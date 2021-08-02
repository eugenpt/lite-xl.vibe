
local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local style = require "core.style"
local translate = require "core.doc.translate"

local misc = require "plugins.lite-xl-vibe.misc"

local function dv()
  return core.active_view
end

local function doc()
  return core.active_view.doc
end

local function is_mode(mode)
  return function() return core.vibe.mode==mode end
end

local function has_selection()
  return doc():has_selection()
end

local com = {}

com.caret_width__orig = style.caret_width

command.add(nil, {
  ["vibe:switch-to-insert-mode"] = function()
    core.vibe.mode = "insert"
  end,
  ["vibe:switch-to-normal-mode"] = function()
    core.vibe.mode = "normal"
  end,
  ["vibe:escape"] = function()
    core.vibe.reset_seq()
  end,
  ["vibe:run-strokes"] = function()
    core.command_view:enter("Strokes to run:", function(text)
      core.vibe.run_stroke_seq(text)
    end)
  end,
  ["vibe:repeat"] = function()
    -- first - remove the last command (the `vibe:repeat` one)
    core.vibe.last_executed_seq = core.vibe.kb.split_stroke_seq(
            core.vibe.last_executed_seq
          )
    core.vibe.last_executed_seq = table.concat(
        {table.unpack(
          core.vibe.last_executed_seq,
          1,
          #core.vibe.last_executed_seq - 1
        )}
      )
    core.vibe.run_stroke_seq(core.vibe.last_executed_seq)
  end,
  ["vibe:repeat-find-in-line"] = function()
    if core.vibe.last_line_find == nil then
      core.vibe.debug_str = 'no last line search..'
      return
    end
    doc():move_to(function(doc,line,col)
      return misc.find_in_line(
        core.vibe.last_line_find["symbol"], 
        core.vibe.last_line_find["backwards"],
        core.vibe.last_line_find["include"],
        doc, line, col
      )
    end, dv())
  end,
  ["vibe:rotate-clipboard-ring"] = function()
    misc.clipboard_ring_rotate()
  end,
  ["vibe:open-scratch-buffer"] = function()
    core.root_view:open_doc(core.open_doc(misc.scratch_filepath()))
  end,
  ["vibe:paste"] = function()
    core.log('vibe:paste')
    local text
    if core.vibe.target_register
       and core.vibe.registers[core.vibe.target_register] then
      system.set_clipboard(core.vibe.registers[core.vibe.target_register], true)
      -- aand zero it back for further actions
      core.vibe.target_register = nil
    end
    if doc():has_selection() then
      text = doc():get_text(doc():get_selection())
    end
    command.perform("doc:paste")
    if text then
      system.set_clipboard(text)
    end
  end,
  ["vibe:delete-symbol-under-cursor"] = function()
      local doc = core.active_view.doc
      local line,col,line2,col2 = doc:get_selection()
      doc:set_selection(line,col)
      doc:delete_to(translate.next_char)
      doc:set_selection(line,col,line2,col2)
  end,
})


command.add(has_selection, {
  ["vibe:copy"] = function()
    core.log('vibe:copy')
    command.perform("doc:copy")
    if core.vibe.target_register then
      core.vibe.registers[core.vibe.target_register] = system.get_clipboard()
      -- aand zero it back for further actions
      core.vibe.target_register = nil
    end
  end,
  ["vibe:delete"] = function()
    core.log('vibe:delete')
    local text = doc():get_text(doc():get_selection())
    if core.vibe.target_register then
      core.vibe.registers[core.vibe.target_register] = text
      -- aand zero it back for further actions
      core.vibe.target_register = nil
    end
    system.set_clipboard(text)
    command.perform("doc:delete")
  end,
})

return com
