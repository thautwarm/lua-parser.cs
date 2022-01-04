do
local core = require "core"
local command = {}

command.map = {}

local always_true = function() return true end


function command.add(predicate, map)
  predicate = predicate or always_true
  if type(predicate) == "string" then
    predicate = require(predicate)
  end
  if type(predicate) == "table" then
    local class = predicate
    predicate = function() return core.active_view:is(class) end
  end
  for name, fn in pairs(map) do
    assert(not command.map[name], "command already exists: " .. name)
    command.map[name] = { predicate = predicate, perform = fn }
  end
end


local function capitalize_first(str)
  return str:sub(1, 1):upper() .. str:sub(2)
end

function command.prettify_name(name)
  return name:gsub(":", ": "):gsub("-", " "):gsub("%S+", capitalize_first)
end


function command.get_all_valid()
  local res = {}
  for name, cmd in pairs(command.map) do
    if cmd.predicate() then
      table.insert(res, name)
    end
  end
  return res
end


local function perform(name)
  local cmd = command.map[name]
  if cmd and cmd.predicate() then
    cmd.perform()
    return true
  end
  return false
end


function command.perform(...)
  local ok, res = core.try(perform, ...)
  return not ok or res
end


function command.add_defaults()
  local reg = { "core", "root", "command", "doc", "findreplace" }
  for _, name in ipairs(reg) do
    require("core.commands." .. name)
  end
end


return command
end

do
local core = require "core"
local common = require "core.common"
local style = require "core.style"
local Doc = require "core.doc"
local DocView = require "core.docview"
local View = require "core.view"


local SingleLineDoc = Doc:extend()

function SingleLineDoc:insert(line, col, text)
  SingleLineDoc.super.insert(self, line, col, text:gsub("\n", ""))
end


local CommandView = DocView:extend()

local max_suggestions = 10

local noop = function() end

local default_state = {
  submit = noop,
  suggest = noop,
  cancel = noop,
}


function CommandView:new()
  CommandView.super.new(self, SingleLineDoc())
  self.suggestion_idx = 1
  self.suggestions = {}
  self.suggestions_height = 0
  self.last_change_id = 0
  self.gutter_width = 0
  self.gutter_text_brightness = 0
  self.selection_offset = 0
  self.state = default_state
  self.font = "font"
  self.size.y = 0
  self.label = ""
end


function CommandView:get_name()
  return View.get_name(self)
end


function CommandView:get_line_screen_position()
  local x = CommandView.super.get_line_screen_position(self, 1)
  local _, y = self:get_content_offset()
  local lh = self:get_line_height()
  return x, y + (self.size.y - lh) / 2
end


function CommandView:get_scrollable_size()
  return 0
end


function CommandView:scroll_to_make_visible()
  -- no-op function to disable this functionality
end


function CommandView:get_text()
  return self.doc:get_text(1, 1, 1, math.huge)
end


function CommandView:set_text(text, select)
  self.doc:remove(1, 1, math.huge, math.huge)
  self.doc:text_input(text)
  if select then
    self.doc:set_selection(math.huge, math.huge, 1, 1)
  end
end


function CommandView:move_suggestion_idx(dir)
  local n = self.suggestion_idx + dir
  self.suggestion_idx = common.clamp(n, 1, #self.suggestions)
  self:complete()
  self.last_change_id = self.doc:get_change_id()
end


function CommandView:complete()
  if #self.suggestions > 0 then
    self:set_text(self.suggestions[self.suggestion_idx].text)
  end
end


function CommandView:submit()
  local suggestion = self.suggestions[self.suggestion_idx]
  local text = self:get_text()
  local submit = self.state.submit
  self:exit(true)
  submit(text, suggestion)
end


function CommandView:enter(text, submit, suggest, cancel)
  if self.state ~= default_state then
    return
  end
  self.state = {
    submit = submit or noop,
    suggest = suggest or noop,
    cancel = cancel or noop,
  }
  core.set_active_view(self)
  self:update_suggestions()
  self.gutter_text_brightness = 100
  self.label = text .. ": "
end


function CommandView:exit(submitted, inexplicit)
  if core.active_view == self then
    core.set_active_view(core.last_active_view)
  end
  local cancel = self.state.cancel
  self.state = default_state
  self.doc:reset()
  self.suggestions = {}
  if not submitted then cancel(not inexplicit) end
end


function CommandView:get_gutter_width()
  return self.gutter_width
end


function CommandView:get_suggestion_line_height()
  return self:get_font():get_height() + style.padding.y
end


function CommandView:update_suggestions()
  local t = self.state.suggest(self:get_text()) or {}
  local res = {}
  for i, item in ipairs(t) do
    if i == max_suggestions then
      break
    end
    if type(item) == "string" then
      item = { text = item }
    end
    res[i] = item
  end
  self.suggestions = res
  self.suggestion_idx = 1
end


function CommandView:update()
  CommandView.super.update(self)

  if core.active_view ~= self and self.state ~= default_state then
    self:exit(false, true)
  end

  -- update suggestions if text has changed
  if self.last_change_id ~= self.doc:get_change_id() then
    self:update_suggestions()
    self.last_change_id = self.doc:get_change_id()
  end

  -- update gutter text color brightness
  self:move_towards("gutter_text_brightness", 0, 0.1)

  -- update gutter width
  local dest = self:get_font():get_width(self.label) + style.padding.x
  if self.size.y <= 0 then
    self.gutter_width = dest
  else
    self:move_towards("gutter_width", dest)
  end

  -- update suggestions box height
  local lh = self:get_suggestion_line_height()
  local dest = #self.suggestions * lh
  self:move_towards("suggestions_height", dest)

  -- update suggestion cursor offset
  local dest = self.suggestion_idx * self:get_suggestion_line_height()
  self:move_towards("selection_offset", dest)

  -- update size based on whether this is the active_view
  local dest = 0
  if self == core.active_view then
    dest = style.font:get_height() + style.padding.y * 2
  end
  self:move_towards(self.size, "y", dest)
end


function CommandView:draw_line_highlight()
  -- no-op function to disable this functionality
end


function CommandView:draw_line_gutter(idx, x, y)
  local yoffset = self:get_line_text_y_offset()
  local pos = self.position
  local color = common.lerp(style.text, style.accent, self.gutter_text_brightness / 100)
  core.push_clip_rect(pos.x, pos.y, self:get_gutter_width(), self.size.y)
  x = x + style.padding.x
  renderer.draw_text(self:get_font(), self.label, x, y + yoffset, color)
  core.pop_clip_rect()
end


local function draw_suggestions_box(self)
  local lh = self:get_suggestion_line_height()
  local dh = style.divider_size
  local x, _ = self:get_line_screen_position()
  local h = math.ceil(self.suggestions_height)
  local rx, ry, rw, rh = self.position.x, self.position.y - h - dh, self.size.x, h

  -- draw suggestions background
  if #self.suggestions > 0 then
    renderer.draw_rect(rx, ry, rw, rh, style.background3)
    renderer.draw_rect(rx, ry - dh, rw, dh, style.divider)
    local y = self.position.y - self.selection_offset - dh
    renderer.draw_rect(rx, y, rw, lh, style.line_highlight)
  end

  -- draw suggestion text
  core.push_clip_rect(rx, ry, rw, rh)
  for i, item in ipairs(self.suggestions) do
    local color = (i == self.suggestion_idx) and style.accent or style.text
    local y = self.position.y - i * lh - dh
    common.draw_text(self:get_font(), color, item.text, nil, x, y, 0, lh)

    if item.info then
      local w = self.size.x - x - style.padding.x
      common.draw_text(self:get_font(), style.dim, item.info, "right", x, y, w, lh)
    end
  end
  core.pop_clip_rect()
end


function CommandView:draw()
  CommandView.super.draw(self)
  core.root_view:defer_draw(draw_suggestions_box, self)
end


return CommandView
end

do
local common = {}


function common.is_utf8_cont(char)
  local byte = char:byte()
  return byte >= 0x80 and byte < 0xc0
end


function common.utf8_chars(text)
  return text:gmatch("[\0-\x7f\xc2-\xf4][\x80-\xbf]*")
end


function common.clamp(n, lo, hi)
  return math.max(math.min(n, hi), lo)
end


function common.round(n)
  return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end


function common.lerp(a, b, t)
  if type(a) ~= "table" then
    return a + (b - a) * t
  end
  local res = {}
  for k, v in pairs(b) do
    res[k] = common.lerp(a[k], v, t)
  end
  return res
end


function common.color(str)
  local r, g, b, a = str:match("#(%x%x)(%x%x)(%x%x)")
  if r then
    r = tonumber(r, 16)
    g = tonumber(g, 16)
    b = tonumber(b, 16)
    a = 1
  elseif str:match("rgba?%s*%([%d%s%.,]+%)") then
    local f = str:gmatch("[%d.]+")
    r = (f() or 0)
    g = (f() or 0)
    b = (f() or 0)
    a = f() or 1
  else
    error(string.format("bad color string '%s'", str))
  end
  return r, g, b, a * 0xff
end


local function compare_score(a, b)
  return a.score > b.score
end

local function fuzzy_match_items(items, needle)
  local res = {}
  for _, item in ipairs(items) do
    local score = system.fuzzy_match(tostring(item), needle)
    if score then
      table.insert(res, { text = item, score = score })
    end
  end
  table.sort(res, compare_score)
  for i, item in ipairs(res) do
    res[i] = item.text
  end
  return res
end


function common.fuzzy_match(haystack, needle)
  if type(haystack) == "table" then
    return fuzzy_match_items(haystack, needle)
  end
  return system.fuzzy_match(haystack, needle)
end


function common.path_suggest(text)
  local path, name = text:match("^(.-)([^/\\]*)$")
  local files = system.list_dir(path == "" and "." or path) or {}
  local res = {}
  for _, file in ipairs(files) do
    file = path .. file
    local info = system.get_file_info(file)
    if info then
      if info.type == "dir" then
        file = file .. PATHSEP
      end
      if file:lower():find(text:lower(), nil, true) == 1 then
        table.insert(res, file)
      end
    end
  end
  return res
end


function common.match_pattern(text, pattern, ...)
  if type(pattern) == "string" then
    return text:find(pattern, ...)
  end
  for _, p in ipairs(pattern) do
    local s, e = common.match_pattern(text, p, ...)
    if s then return s, e end
  end
  return false
end


function common.draw_text(font, color, text, align, x,y,w,h)
  local tw, th = font:get_width(text), font:get_height(text)
  if align == "center" then
    x = x + (w - tw) / 2
  elseif align == "right" then
    x = x + (w - tw)
  end
  y = common.round(y + (h - th) / 2)
  return renderer.draw_text(font, text, x, y, color), y + th
end


function common.bench(name, fn, ...)
  local start = system.get_time()
  local res = fn(...)
  local t = system.get_time() - start
  local ms = t * 1000
  local per = (t / (1 / 60)) * 100
  print(string.format("*** %-16s : %8.3fms %6.2f%%", name, ms, per))
  return res
end


return common
end

do
local config = {}

config.project_scan_rate = 5
config.fps = 60
config.max_log_items = 80
config.message_timeout = 3
config.mouse_wheel_scroll = 50 * SCALE
config.file_size_limit = 10
config.ignore_files = "^%."
config.symbol_pattern = "[%a_][%w_]*"
config.non_word_chars = " \t\n/\\()\"':,.;<>~!@#$%^&*|+=[]{}`?-"
config.undo_merge_timeout = 0.3
config.max_undos = 10000
config.highlight_current_line = true
config.line_height = 1.2
config.indent_size = 2
config.tab_type = "soft"
config.line_limit = 80

return config
end

do
local core = require "core"
local common = require "core.common"
local config = require "core.config"
local style = require "core.style"
local keymap = require "core.keymap"
local translate = require "core.doc.translate"
local View = require "core.view"


local DocView = View:extend()


local function move_to_line_offset(dv, line, col, offset)
  local xo = dv.last_x_offset
  if xo.line ~= line or xo.col ~= col then
    xo.offset = dv:get_col_x_offset(line, col)
  end
  xo.line = line + offset
  xo.col = dv:get_x_offset_col(line + offset, xo.offset)
  return xo.line, xo.col
end


DocView.translate = {
  ["previous_page"] = function(doc, line, col, dv)
    local min, max = dv:get_visible_line_range()
    return line - (max - min), 1
  end,

  ["next_page"] = function(doc, line, col, dv)
    local min, max = dv:get_visible_line_range()
    return line + (max - min), 1
  end,

  ["previous_line"] = function(doc, line, col, dv)
    if line == 1 then
      return 1, 1
    end
    return move_to_line_offset(dv, line, col, -1)
  end,

  ["next_line"] = function(doc, line, col, dv)
    if line == #doc.lines then
      return #doc.lines, math.huge
    end
    return move_to_line_offset(dv, line, col, 1)
  end,
}

local blink_period = 0.8


function DocView:new(doc)
  DocView.super.new(self)
  self.cursor = "ibeam"
  self.scrollable = true
  self.doc = assert(doc)
  self.font = "code_font"
  self.last_x_offset = {}
  self.blink_timer = 0
end


function DocView:try_close(do_close)
  if self.doc:is_dirty()
  and #core.get_views_referencing_doc(self.doc) == 1 then
    core.command_view:enter("Unsaved Changes; Confirm Close", function(_, item)
      if item.text:match("^[cC]") then
        do_close()
      elseif item.text:match("^[sS]") then
        self.doc:save()
        do_close()
      end
    end, function(text)
      local items = {}
      if not text:find("^[^cC]") then table.insert(items, "Close Without Saving") end
      if not text:find("^[^sS]") then table.insert(items, "Save And Close") end
      return items
    end)
  else
    do_close()
  end
end


function DocView:get_name()
  local post = self.doc:is_dirty() and "*" or ""
  local name = self.doc:get_name()
  return name:match("[^/%\\]*$") .. post
end


function DocView:get_scrollable_size()
  return self:get_line_height() * (#self.doc.lines - 1) + self.size.y
end


function DocView:get_font()
  return style[self.font]
end


function DocView:get_line_height()
  return math.floor(self:get_font():get_height() * config.line_height)
end


function DocView:get_gutter_width()
  return self:get_font():get_width(#self.doc.lines) + style.padding.x * 2
end


function DocView:get_line_screen_position(idx)
  local x, y = self:get_content_offset()
  local lh = self:get_line_height()
  local gw = self:get_gutter_width()
  return x + gw, y + (idx - 1) * lh + style.padding.y
end


function DocView:get_line_text_y_offset()
  local lh = self:get_line_height()
  local th = self:get_font():get_height()
  return (lh - th) / 2
end


function DocView:get_visible_line_range()
  local x, y, x2, y2 = self:get_content_bounds()
  local lh = self:get_line_height()
  local minline = math.max(1, math.floor(y / lh))
  local maxline = math.min(#self.doc.lines, math.floor(y2 / lh) + 1)
  return minline, maxline
end


function DocView:get_col_x_offset(line, col)
  local text = self.doc.lines[line]
  if not text then return 0 end
  return self:get_font():get_width(text:sub(1, col - 1))
end


function DocView:get_x_offset_col(line, x)
  local text = self.doc.lines[line]

  local xoffset, last_i, i = 0, 1, 1
  for char in common.utf8_chars(text) do
    local w = self:get_font():get_width(char)
    if xoffset >= x then
      return (xoffset - x > w / 2) and last_i or i
    end
    xoffset = xoffset + w
    last_i = i
    i = i + #char
  end

  return #text
end


function DocView:resolve_screen_position(x, y)
  local ox, oy = self:get_line_screen_position(1)
  local line = math.floor((y - oy) / self:get_line_height()) + 1
  line = common.clamp(line, 1, #self.doc.lines)
  local col = self:get_x_offset_col(line, x - ox)
  return line, col
end


function DocView:scroll_to_line(line, ignore_if_visible, instant)
  local min, max = self:get_visible_line_range()
  if not (ignore_if_visible and line > min and line < max) then
    local lh = self:get_line_height()
    self.scroll.to.y = math.max(0, lh * (line - 1) - self.size.y / 2)
    if instant then
      self.scroll.y = self.scroll.to.y
    end
  end
end


function DocView:scroll_to_make_visible(line, col)
  local min = self:get_line_height() * (line - 1)
  local max = self:get_line_height() * (line + 2) - self.size.y
  self.scroll.to.y = math.min(self.scroll.to.y, min)
  self.scroll.to.y = math.max(self.scroll.to.y, max)
  local gw = self:get_gutter_width()
  local xoffset = self:get_col_x_offset(line, col)
  local max = xoffset - self.size.x + gw + self.size.x / 5
  self.scroll.to.x = math.max(0, max)
end


local function mouse_selection(doc, clicks, line1, col1, line2, col2)
  local swap = line2 < line1 or line2 == line1 and col2 <= col1
  if swap then
    line1, col1, line2, col2 = line2, col2, line1, col1
  end
  if clicks == 2 then
    line1, col1 = translate.start_of_word(doc, line1, col1)
    line2, col2 = translate.end_of_word(doc, line2, col2)
  elseif clicks == 3 then
    if line2 == #doc.lines and doc.lines[#doc.lines] ~= "\n" then
      doc:insert(math.huge, math.huge, "\n")
    end
    line1, col1, line2, col2 = line1, 1, line2 + 1, 1
  end
  if swap then
    return line2, col2, line1, col1
  end
  return line1, col1, line2, col2
end


function DocView:on_mouse_pressed(button, x, y, clicks)
  local caught = DocView.super.on_mouse_pressed(self, button, x, y, clicks)
  if caught then
    return
  end
  if keymap.modkeys["shift"] then
    if clicks == 1 then
      local line1, col1 = select(3, self.doc:get_selection())
      local line2, col2 = self:resolve_screen_position(x, y)
      self.doc:set_selection(line2, col2, line1, col1)
    end
  else
    local line, col = self:resolve_screen_position(x, y)
    self.doc:set_selection(mouse_selection(self.doc, clicks, line, col, line, col))
    self.mouse_selecting = { line, col, clicks = clicks }
  end
  self.blink_timer = 0
end


function DocView:on_mouse_moved(x, y, ...)
  DocView.super.on_mouse_moved(self, x, y, ...)

  if self:scrollbar_overlaps_point(x, y) or self.dragging_scrollbar then
    self.cursor = "arrow"
  else
    self.cursor = "ibeam"
  end

  if self.mouse_selecting then
    local l1, c1 = self:resolve_screen_position(x, y)
    local l2, c2 = table.unpack(self.mouse_selecting)
    local clicks = self.mouse_selecting.clicks
    self.doc:set_selection(mouse_selection(self.doc, clicks, l1, c1, l2, c2))
  end
end


function DocView:on_mouse_released(button)
  DocView.super.on_mouse_released(self, button)
  self.mouse_selecting = nil
end


function DocView:on_text_input(text)
  self.doc:text_input(text)
end


function DocView:update()
  -- scroll to make caret visible and reset blink timer if it moved
  local line, col = self.doc:get_selection()
  if (line ~= self.last_line or col ~= self.last_col) and self.size.x > 0 then
    if core.active_view == self then
      self:scroll_to_make_visible(line, col)
    end
    self.blink_timer = 0
    self.last_line, self.last_col = line, col
  end

  -- update blink timer
  if self == core.active_view and not self.mouse_selecting then
    local n = blink_period / 2
    local prev = self.blink_timer
    self.blink_timer = (self.blink_timer + 1 / config.fps) % blink_period
    if (self.blink_timer > n) ~= (prev > n) then
      core.redraw = true
    end
  end

  DocView.super.update(self)
end


function DocView:draw_line_highlight(x, y)
  local lh = self:get_line_height()
  renderer.draw_rect(x, y, self.size.x, lh, style.line_highlight)
end


function DocView:draw_line_text(idx, x, y)
  local tx, ty = x, y + self:get_line_text_y_offset()
  local font = self:get_font()
  for _, type, text in self.doc.highlighter:each_token(idx) do
    local color = style.syntax[type]
    tx = renderer.draw_text(font, text, tx, ty, color)
  end
end


function DocView:draw_line_body(idx, x, y)
  local line, col = self.doc:get_selection()

  -- draw selection if it overlaps this line
  local line1, col1, line2, col2 = self.doc:get_selection(true)
  if idx >= line1 and idx <= line2 then
    local text = self.doc.lines[idx]
    if line1 ~= idx then col1 = 1 end
    if line2 ~= idx then col2 = #text + 1 end
    local x1 = x + self:get_col_x_offset(idx, col1)
    local x2 = x + self:get_col_x_offset(idx, col2)
    local lh = self:get_line_height()
    renderer.draw_rect(x1, y, x2 - x1, lh, style.selection)
  end

  -- draw line highlight if caret is on this line
  if config.highlight_current_line and not self.doc:has_selection()
  and line == idx and core.active_view == self then
    self:draw_line_highlight(x + self.scroll.x, y)
  end

  -- draw line's text
  self:draw_line_text(idx, x, y)

  -- draw caret if it overlaps this line
  if line == idx and core.active_view == self
  and self.blink_timer < blink_period / 2
  and system.window_has_focus() then
    local lh = self:get_line_height()
    local x1 = x + self:get_col_x_offset(line, col)
    renderer.draw_rect(x1, y, style.caret_width, lh, style.caret)
  end
end


function DocView:draw_line_gutter(idx, x, y)
  local color = style.line_number
  local line1, _, line2, _ = self.doc:get_selection(true)
  if idx >= line1 and idx <= line2 then
    color = style.line_number2
  end
  local yoffset = self:get_line_text_y_offset()
  x = x + style.padding.x
  renderer.draw_text(self:get_font(), idx, x, y + yoffset, color)
end


function DocView:draw()
  self:draw_background(style.background)

  local font = self:get_font()
  font:set_tab_width(font:get_width(" ") * config.indent_size)

  local minline, maxline = self:get_visible_line_range()
  local lh = self:get_line_height()

  local _, y = self:get_line_screen_position(minline)
  local x = self.position.x
  for i = minline, maxline do
    self:draw_line_gutter(i, x, y)
    y = y + lh
  end

  local x, y = self:get_line_screen_position(minline)
  local gw = self:get_gutter_width()
  local pos = self.position
  core.push_clip_rect(pos.x + gw, pos.y, self.size.x, self.size.y)
  for i = minline, maxline do
    self:draw_line_body(i, x, y)
    y = y + lh
  end
  core.pop_clip_rect()

  self:draw_scrollbar()
end


return DocView
end

do
require "core.strict"
local common = require "core.common"
local config = require "core.config"
local style = require "core.style"
local command
local keymap
local RootView
local StatusView
local CommandView
local Doc

local core = {}


local function project_scan_thread()
  local function diff_files(a, b)
    if #a ~= #b then return true end
    for i, v in ipairs(a) do
      if b[i].filename ~= v.filename
      or b[i].modified ~= v.modified then
        return true
      end
    end
  end

  local function compare_file(a, b)
    return a.filename < b.filename
  end

  local function get_files(path, t)
    coroutine.yield()
    t = t or {}
    local size_limit = config.file_size_limit * 10e5
    local all = system.list_dir(path) or {}
    local dirs, files = {}, {}

    for _, file in ipairs(all) do
      if not common.match_pattern(file, config.ignore_files) then
        local file = (path ~= "." and path .. PATHSEP or "") .. file
        local info = system.get_file_info(file)
        if info and info.size < size_limit then
          info.filename = file
          table.insert(info.type == "dir" and dirs or files, info)
        end
      end
    end

    table.sort(dirs, compare_file)
    for _, f in ipairs(dirs) do
      table.insert(t, f)
      get_files(f.filename, t)
    end

    table.sort(files, compare_file)
    for _, f in ipairs(files) do
      table.insert(t, f)
    end

    return t
  end

  while true do
    -- get project files and replace previous table if the new table is
    -- different
    local t = get_files(".")
    if diff_files(core.project_files, t) then
      core.project_files = t
      core.redraw = true
    end

    -- wait for next scan
    coroutine.yield(config.project_scan_rate)
  end
end


function core.init()
  command = require "core.command"
  keymap = require "core.keymap"
  RootView = require "core.rootview"
  StatusView = require "core.statusview"
  CommandView = require "core.commandview"
  Doc = require "core.doc"

  local project_dir = EXEDIR
  local files = {}
  for i = 2, #ARGS do
    local info = system.get_file_info(ARGS[i]) or {}
    if info.type == "file" then
      table.insert(files, system.absolute_path(ARGS[i]))
    elseif info.type == "dir" then
      project_dir = ARGS[i]
    end
  end

  system.chdir(project_dir)

  core.frame_start = 0
  core.clip_rect_stack = {{ 0,0,0,0 }}
  core.log_items = {}
  core.docs = {}
  core.threads = setmetatable({}, { __mode = "k" })
  core.project_files = {}
  core.redraw = true

  core.root_view = RootView()
  core.command_view = CommandView()
  core.status_view = StatusView()

  core.root_view.root_node:split("down", core.command_view, true)
  core.root_view.root_node.b:split("down", core.status_view, true)

  core.add_thread(project_scan_thread)
  command.add_defaults()
  local got_plugin_error = not core.load_plugins()
  local got_user_error = not core.try(require, "user")
  local got_project_error = not core.load_project_module()

  for _, filename in ipairs(files) do
    core.root_view:open_doc(core.open_doc(filename))
  end

  if got_plugin_error or got_user_error or got_project_error then
    command.perform("core:open-log")
  end
end


local temp_uid = (system.get_time() * 1000) % 0xffffffff
local temp_file_prefix = string.format(".lite_temp_%08x", temp_uid)
local temp_file_counter = 0

local function delete_temp_files()
  for _, filename in ipairs(system.list_dir(EXEDIR)) do
    if filename:find(temp_file_prefix, 1, true) == 1 then
      os.remove(EXEDIR .. PATHSEP .. filename)
    end
  end
end

function core.temp_filename(ext)
  temp_file_counter = temp_file_counter + 1
  return EXEDIR .. PATHSEP .. temp_file_prefix
      .. string.format("%06x", temp_file_counter) .. (ext or "")
end


function core.quit(force)
  if force then
    delete_temp_files()
    os.exit()
  end
  local dirty_count = 0
  local dirty_name
  for _, doc in ipairs(core.docs) do
    if doc:is_dirty() then
      dirty_count = dirty_count + 1
      dirty_name = doc:get_name()
    end
  end
  if dirty_count > 0 then
    local text
    if dirty_count == 1 then
      text = string.format("\"%s\" has unsaved changes. Quit anyway?", dirty_name)
    else
      text = string.format("%d docs have unsaved changes. Quit anyway?", dirty_count)
    end
    local confirm = system.show_confirm_dialog("Unsaved Changes", text)
    if not confirm then return end
  end
  core.quit(true)
end


function core.load_plugins()
  local no_errors = true
  local files = system.list_dir(EXEDIR .. "/data/plugins")
  for _, filename in ipairs(files) do
    local modname = "plugins." .. filename:gsub(".lua$", "")
    local ok = core.try(require, modname)
    if ok then
      core.log_quiet("Loaded plugin %q", modname)
    else
      no_errors = false
    end
  end
  return no_errors
end


function core.load_project_module()
  local filename = ".lite_project.lua"
  if system.get_file_info(filename) then
    return core.try(function()
      local fn, err = loadfile(filename)
      if not fn then error("Error when loading project module:\n\t" .. err) end
      fn()
      core.log_quiet("Loaded project module")
    end)
  end
  return true
end


function core.reload_module(name)
  local old = package.loaded[name]
  package.loaded[name] = nil
  local new = require(name)
  if type(old) == "table" then
    for k, v in pairs(new) do old[k] = v end
    package.loaded[name] = old
  end
end


function core.set_active_view(view)
  assert(view, "Tried to set active view to nil")
  if view ~= core.active_view then
    core.last_active_view = core.active_view
    core.active_view = view
  end
end


function core.add_thread(f, weak_ref)
  local key = weak_ref or #core.threads + 1
  local fn = function() return core.try(f) end
  core.threads[key] = { cr = coroutine.create(fn), wake = 0 }
end


function core.push_clip_rect(x, y, w, h)
  local x2, y2, w2, h2 = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  local r, b, r2, b2 = x+w, y+h, x2+w2, y2+h2
  x, y = math.max(x, x2), math.max(y, y2)
  b, r = math.min(b, b2), math.min(r, r2)
  w, h = r-x, b-y
  table.insert(core.clip_rect_stack, { x, y, w, h })
  renderer.set_clip_rect(x, y, w, h)
end


function core.pop_clip_rect()
  table.remove(core.clip_rect_stack)
  local x, y, w, h = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  renderer.set_clip_rect(x, y, w, h)
end


function core.open_doc(filename)
  if filename then
    -- try to find existing doc for filename
    local abs_filename = system.absolute_path(filename)
    for _, doc in ipairs(core.docs) do
      if doc.filename
      and abs_filename == system.absolute_path(doc.filename) then
        return doc
      end
    end
  end
  -- no existing doc for filename; create new
  local doc = Doc(filename)
  table.insert(core.docs, doc)
  core.log_quiet(filename and "Opened doc \"%s\"" or "Opened new doc", filename)
  return doc
end


function core.get_views_referencing_doc(doc)
  local res = {}
  local views = core.root_view.root_node:get_children()
  for _, view in ipairs(views) do
    if view.doc == doc then table.insert(res, view) end
  end
  return res
end


local function log(icon, icon_color, fmt, ...)
  local text = string.format(fmt, ...)
  if icon then
    core.status_view:show_message(icon, icon_color, text)
  end

  local info = debug.getinfo(2, "Sl")
  local at = string.format("%s:%d", info.short_src, info.currentline)
  local item = { text = text, time = os.time(), at = at }
  table.insert(core.log_items, item)
  if #core.log_items > config.max_log_items then
    table.remove(core.log_items, 1)
  end
  return item
end


function core.log(...)
  return log("i", style.text, ...)
end


function core.log_quiet(...)
  return log(nil, nil, ...)
end


function core.error(...)
  return log("!", style.accent, ...)
end


function core.try(fn, ...)
  local err
  local ok, res = xpcall(fn, function(msg)
    local item = core.error("%s", msg)
    item.info = debug.traceback(nil, 2):gsub("\t", "")
    err = msg
  end, ...)
  if ok then
    return true, res
  end
  return false, err
end


function core.on_event(type, ...)
  local did_keymap = false
  if type == "textinput" then
    core.root_view:on_text_input(...)
  elseif type == "keypressed" then
    did_keymap = keymap.on_key_pressed(...)
  elseif type == "keyreleased" then
    keymap.on_key_released(...)
  elseif type == "mousemoved" then
    core.root_view:on_mouse_moved(...)
  elseif type == "mousepressed" then
    core.root_view:on_mouse_pressed(...)
  elseif type == "mousereleased" then
    core.root_view:on_mouse_released(...)
  elseif type == "mousewheel" then
    core.root_view:on_mouse_wheel(...)
  elseif type == "filedropped" then
    local filename, mx, my = ...
    local info = system.get_file_info(filename)
    if info and info.type == "dir" then
      system.exec(string.format("%q %q", EXEFILE, filename))
    else
      local ok, doc = core.try(core.open_doc, filename)
      if ok then
        local node = core.root_view.root_node:get_child_overlapping_point(mx, my)
        node:set_active_view(node.active_view)
        core.root_view:open_doc(doc)
      end
    end
  elseif type == "quit" then
    core.quit()
  end
  return did_keymap
end


function core.step()
  -- handle events
  local did_keymap = false
  local mouse_moved = false
  local mouse = { x = 0, y = 0, dx = 0, dy = 0 }

  for type, a,b,c,d in system.poll_event do
    if type == "mousemoved" then
      mouse_moved = true
      mouse.x, mouse.y = a, b
      mouse.dx, mouse.dy = mouse.dx + c, mouse.dy + d
    elseif type == "textinput" and did_keymap then
      did_keymap = false
    else
      local _, res = core.try(core.on_event, type, a, b, c, d)
      did_keymap = res or did_keymap
    end
    core.redraw = true
  end
  if mouse_moved then
    core.try(core.on_event, "mousemoved", mouse.x, mouse.y, mouse.dx, mouse.dy)
  end

  local width, height = renderer.get_size()

  -- update
  core.root_view.size.x, core.root_view.size.y = width, height
  core.root_view:update()
  if not core.redraw then return false end
  core.redraw = false

  -- close unreferenced docs
  for i = #core.docs, 1, -1 do
    local doc = core.docs[i]
    if #core.get_views_referencing_doc(doc) == 0 then
      table.remove(core.docs, i)
      core.log_quiet("Closed doc \"%s\"", doc:get_name())
    end
  end

  -- update window title
  local name = core.active_view:get_name()
  local title = (name ~= "---") and (name .. " - lite") or  "lite"
  if title ~= core.window_title then
    system.set_window_title(title)
    core.window_title = title
  end

  -- draw
  renderer.begin_frame()
  core.clip_rect_stack[1] = { 0, 0, width, height }
  renderer.set_clip_rect(table.unpack(core.clip_rect_stack[1]))
  core.root_view:draw()
  renderer.end_frame()
  return true
end


local run_threads = coroutine.wrap(function()
  while true do
    local max_time = 1 / config.fps - 0.004
    local ran_any_threads = false

    for k, thread in pairs(core.threads) do
      -- run thread
      if thread.wake < system.get_time() then
        local _, wait = assert(coroutine.resume(thread.cr))
        if coroutine.status(thread.cr) == "dead" then
          if type(k) == "number" then
            table.remove(core.threads, k)
          else
            core.threads[k] = nil
          end
        elseif wait then
          thread.wake = system.get_time() + wait
        end
        ran_any_threads = true
      end

      -- stop running threads if we're about to hit the end of frame
      if system.get_time() - core.frame_start > max_time then
        coroutine.yield()
      end
    end

    if not ran_any_threads then coroutine.yield() end
  end
end)


function core.run()
  while true do
    core.frame_start = system.get_time()
    local did_redraw = core.step()
    run_threads()
    if not did_redraw and not system.window_has_focus() then
      system.wait_event(0.25)
    end
    local elapsed = system.get_time() - core.frame_start
    system.sleep(math.max(0, 1 / config.fps - elapsed))
  end
end


function core.on_error(err)
  -- write error to file
  local fp = io.open(EXEDIR .. "/error.txt", "wb")
  fp:write("Error: " .. tostring(err) .. "\n")
  fp:write(debug.traceback(nil, 4))
  fp:close()
  -- save copy of all unsaved documents
  for _, doc in ipairs(core.docs) do
    if doc:is_dirty() and doc.filename then
      doc:save(doc.filename .. "~")
    end
  end
end


return core
end

do
local command = require "core.command"
local keymap = {}

keymap.modkeys = {}
keymap.map = {}
keymap.reverse_map = {}

local modkey_map = {
  ["left ctrl"]   = "ctrl",
  ["right ctrl"]  = "ctrl",
  ["left shift"]  = "shift",
  ["right shift"] = "shift",
  ["left alt"]    = "alt",
  ["right alt"]   = "altgr",
}

local modkeys = { "ctrl", "alt", "altgr", "shift" }

local function key_to_stroke(k)
  local stroke = ""
  for _, mk in ipairs(modkeys) do
    if keymap.modkeys[mk] then
      stroke = stroke .. mk .. "+"
    end
  end
  return stroke .. k
end


function keymap.add(map, overwrite)
  for stroke, commands in pairs(map) do
    if type(commands) == "string" then
      commands = { commands }
    end
    if overwrite then
      keymap.map[stroke] = commands
    else
      keymap.map[stroke] = keymap.map[stroke] or {}
      for i = #commands, 1, -1 do
        table.insert(keymap.map[stroke], 1, commands[i])
      end
    end
    for _, cmd in ipairs(commands) do
      keymap.reverse_map[cmd] = stroke
    end
  end
end


function keymap.get_binding(cmd)
  return keymap.reverse_map[cmd]
end


function keymap.on_key_pressed(k)
  local mk = modkey_map[k]
  if mk then
    keymap.modkeys[mk] = true
    -- work-around for windows where `altgr` is treated as `ctrl+alt`
    if mk == "altgr" then
      keymap.modkeys["ctrl"] = false
    end
  else
    local stroke = key_to_stroke(k)
    local commands = keymap.map[stroke]
    if commands then
      for _, cmd in ipairs(commands) do
        local performed = command.perform(cmd)
        if performed then break end
      end
      return true
    end
  end
  return false
end


function keymap.on_key_released(k)
  local mk = modkey_map[k]
  if mk then
    keymap.modkeys[mk] = false
  end
end


keymap.add {
  ["ctrl+shift+p"] = "core:find-command",
  ["ctrl+p"] = "core:find-file",
  ["ctrl+o"] = "core:open-file",
  ["ctrl+n"] = "core:new-doc",
  ["alt+return"] = "core:toggle-fullscreen",

  ["alt+shift+j"] = "root:split-left",
  ["alt+shift+l"] = "root:split-right",
  ["alt+shift+i"] = "root:split-up",
  ["alt+shift+k"] = "root:split-down",
  ["alt+j"] = "root:switch-to-left",
  ["alt+l"] = "root:switch-to-right",
  ["alt+i"] = "root:switch-to-up",
  ["alt+k"] = "root:switch-to-down",

  ["ctrl+w"] = "root:close",
  ["ctrl+tab"] = "root:switch-to-next-tab",
  ["ctrl+shift+tab"] = "root:switch-to-previous-tab",
  ["ctrl+pageup"] = "root:move-tab-left",
  ["ctrl+pagedown"] = "root:move-tab-right",
  ["alt+1"] = "root:switch-to-tab-1",
  ["alt+2"] = "root:switch-to-tab-2",
  ["alt+3"] = "root:switch-to-tab-3",
  ["alt+4"] = "root:switch-to-tab-4",
  ["alt+5"] = "root:switch-to-tab-5",
  ["alt+6"] = "root:switch-to-tab-6",
  ["alt+7"] = "root:switch-to-tab-7",
  ["alt+8"] = "root:switch-to-tab-8",
  ["alt+9"] = "root:switch-to-tab-9",

  ["ctrl+f"] = "find-replace:find",
  ["ctrl+r"] = "find-replace:replace",
  ["f3"] = "find-replace:repeat-find",
  ["shift+f3"] = "find-replace:previous-find",
  ["ctrl+g"] = "doc:go-to-line",
  ["ctrl+s"] = "doc:save",
  ["ctrl+shift+s"] = "doc:save-as",

  ["ctrl+z"] = "doc:undo",
  ["ctrl+y"] = "doc:redo",
  ["ctrl+x"] = "doc:cut",
  ["ctrl+c"] = "doc:copy",
  ["ctrl+v"] = "doc:paste",
  ["escape"] = { "command:escape", "doc:select-none" },
  ["tab"] = { "command:complete", "doc:indent" },
  ["shift+tab"] = "doc:unindent",
  ["backspace"] = "doc:backspace",
  ["shift+backspace"] = "doc:backspace",
  ["ctrl+backspace"] = "doc:delete-to-previous-word-start",
  ["ctrl+shift+backspace"] = "doc:delete-to-previous-word-start",
  ["delete"] = "doc:delete",
  ["shift+delete"] = "doc:delete",
  ["ctrl+delete"] = "doc:delete-to-next-word-end",
  ["ctrl+shift+delete"] = "doc:delete-to-next-word-end",
  ["return"] = { "command:submit", "doc:newline" },
  ["keypad enter"] = { "command:submit", "doc:newline" },
  ["ctrl+return"] = "doc:newline-below",
  ["ctrl+shift+return"] = "doc:newline-above",
  ["ctrl+j"] = "doc:join-lines",
  ["ctrl+a"] = "doc:select-all",
  ["ctrl+d"] = { "find-replace:select-next", "doc:select-word" },
  ["ctrl+l"] = "doc:select-lines",
  ["ctrl+/"] = "doc:toggle-line-comments",
  ["ctrl+up"] = "doc:move-lines-up",
  ["ctrl+down"] = "doc:move-lines-down",
  ["ctrl+shift+d"] = "doc:duplicate-lines",
  ["ctrl+shift+k"] = "doc:delete-lines",

  ["left"] = "doc:move-to-previous-char",
  ["right"] = "doc:move-to-next-char",
  ["up"] = { "command:select-previous", "doc:move-to-previous-line" },
  ["down"] = { "command:select-next", "doc:move-to-next-line" },
  ["ctrl+left"] = "doc:move-to-previous-word-start",
  ["ctrl+right"] = "doc:move-to-next-word-end",
  ["ctrl+["] = "doc:move-to-previous-block-start",
  ["ctrl+]"] = "doc:move-to-next-block-end",
  ["home"] = "doc:move-to-start-of-line",
  ["end"] = "doc:move-to-end-of-line",
  ["ctrl+home"] = "doc:move-to-start-of-doc",
  ["ctrl+end"] = "doc:move-to-end-of-doc",
  ["pageup"] = "doc:move-to-previous-page",
  ["pagedown"] = "doc:move-to-next-page",

  ["shift+left"] = "doc:select-to-previous-char",
  ["shift+right"] = "doc:select-to-next-char",
  ["shift+up"] = "doc:select-to-previous-line",
  ["shift+down"] = "doc:select-to-next-line",
  ["ctrl+shift+left"] = "doc:select-to-previous-word-start",
  ["ctrl+shift+right"] = "doc:select-to-next-word-end",
  ["ctrl+shift+["] = "doc:select-to-previous-block-start",
  ["ctrl+shift+]"] = "doc:select-to-next-block-end",
  ["shift+home"] = "doc:select-to-start-of-line",
  ["shift+end"] = "doc:select-to-end-of-line",
  ["ctrl+shift+home"] = "doc:select-to-start-of-doc",
  ["ctrl+shift+end"] = "doc:select-to-end-of-doc",
  ["shift+pageup"] = "doc:select-to-previous-page",
  ["shift+pagedown"] = "doc:select-to-next-page",
}

return keymap
end

do
local core = require "core"
local style = require "core.style"
local View = require "core.view"


local LogView = View:extend()


function LogView:new()
  LogView.super.new(self)
  self.last_item = core.log_items[#core.log_items]
  self.scrollable = true
  self.yoffset = 0
end


function LogView:get_name()
  return "Log"
end


function LogView:update()
  local item = core.log_items[#core.log_items]
  if self.last_item ~= item then
    self.last_item = item
    self.scroll.to.y = 0
    self.yoffset = -(style.font:get_height() + style.padding.y)
  end

  self:move_towards("yoffset", 0)

  LogView.super.update(self)
end


local function draw_text_multiline(font, text, x, y, color)
  local th = font:get_height()
  local resx, resy = x, y
  for line in text:gmatch("[^\n]+") do
    resy = y
    resx = renderer.draw_text(style.font, line, x, y, color)
    y = y + th
  end
  return resx, resy
end


function LogView:draw()
  self:draw_background(style.background)

  local ox, oy = self:get_content_offset()
  local th = style.font:get_height()
  local y = oy + style.padding.y + self.yoffset

  for i = #core.log_items, 1, -1 do
    local x = ox + style.padding.x
    local item = core.log_items[i]
    local time = os.date(nil, item.time)
    x = renderer.draw_text(style.font, time, x, y, style.dim)
    x = x + style.padding.x
    local subx = x
    x, y = draw_text_multiline(style.font, item.text, x, y, style.text)
    renderer.draw_text(style.font, " at " .. item.at, x, y, style.dim)
    y = y + th
    if item.info then
      subx, y = draw_text_multiline(style.font, item.info, subx, y, style.dim)
      y = y + th
    end
    y = y + style.padding.y
  end
end


return LogView
end

do
local Object = {}
Object.__index = Object


function Object:new()
end


function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)
  return cls
end


function Object:implement(...)
  for _, cls in pairs({...}) do
    for k, v in pairs(cls) do
      if self[k] == nil and type(v) == "function" then
        self[k] = v
      end
    end
  end
end


function Object:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end


function Object:__tostring()
  return "Object"
end


function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end


return Object
end

do
local core = require "core"
local common = require "core.common"
local style = require "core.style"
local keymap = require "core.keymap"
local Object = require "core.object"
local View = require "core.view"
local DocView = require "core.docview"


local EmptyView = View:extend()

local function draw_text(x, y, color)
  local th = style.big_font:get_height()
  local dh = th + style.padding.y * 2
  x = renderer.draw_text(style.big_font, "lite", x, y + (dh - th) / 2, color)
  x = x + style.padding.x
  renderer.draw_rect(x, y, math.ceil(1 * SCALE), dh, color)
  local lines = {
    { fmt = "%s to run a command", cmd = "core:find-command" },
    { fmt = "%s to open a file from the project", cmd = "core:find-file" },
  }
  th = style.font:get_height()
  y = y + (dh - th * 2 - style.padding.y) / 2
  local w = 0
  for _, line in ipairs(lines) do
    local text = string.format(line.fmt, keymap.get_binding(line.cmd))
    w = math.max(w, renderer.draw_text(style.font, text, x + style.padding.x, y, color))
    y = y + th + style.padding.y
  end
  return w, dh
end

function EmptyView:draw()
  self:draw_background(style.background)
  local w, h = draw_text(0, 0, { 0, 0, 0, 0 })
  local x = self.position.x + math.max(style.padding.x, (self.size.x - w) / 2)
  local y = self.position.y + (self.size.y - h) / 2
  draw_text(x, y, style.dim)
end



local Node = Object:extend()

function Node:new(type)
  self.type = type or "leaf"
  self.position = { x = 0, y = 0 }
  self.size = { x = 0, y = 0 }
  self.views = {}
  self.divider = 0.5
  if self.type == "leaf" then
    self:add_view(EmptyView())
  end
end


function Node:propagate(fn, ...)
  self.a[fn](self.a, ...)
  self.b[fn](self.b, ...)
end


function Node:on_mouse_moved(x, y, ...)
  self.hovered_tab = self:get_tab_overlapping_point(x, y)
  if self.type == "leaf" then
    self.active_view:on_mouse_moved(x, y, ...)
  else
    self:propagate("on_mouse_moved", x, y, ...)
  end
end


function Node:on_mouse_released(...)
  if self.type == "leaf" then
    self.active_view:on_mouse_released(...)
  else
    self:propagate("on_mouse_released", ...)
  end
end


function Node:consume(node)
  for k, _ in pairs(self) do self[k] = nil end
  for k, v in pairs(node) do self[k] = v   end
end


local type_map = { up="vsplit", down="vsplit", left="hsplit", right="hsplit" }

function Node:split(dir, view, locked)
  assert(self.type == "leaf", "Tried to split non-leaf node")
  local type = assert(type_map[dir], "Invalid direction")
  local last_active = core.active_view
  local child = Node()
  child:consume(self)
  self:consume(Node(type))
  self.a = child
  self.b = Node()
  if view then self.b:add_view(view) end
  if locked then
    self.b.locked = locked
    core.set_active_view(last_active)
  end
  if dir == "up" or dir == "left" then
    self.a, self.b = self.b, self.a
  end
  return child
end


function Node:close_active_view(root)
  local do_close = function()
    if #self.views > 1 then
      local idx = self:get_view_idx(self.active_view)
      table.remove(self.views, idx)
      self:set_active_view(self.views[idx] or self.views[#self.views])
    else
      local parent = self:get_parent_node(root)
      local is_a = (parent.a == self)
      local other = parent[is_a and "b" or "a"]
      if other:get_locked_size() then
        self.views = {}
        self:add_view(EmptyView())
      else
        parent:consume(other)
        local p = parent
        while p.type ~= "leaf" do
          p = p[is_a and "a" or "b"]
        end
        p:set_active_view(p.active_view)
      end
    end
    core.last_active_view = nil
  end
  self.active_view:try_close(do_close)
end


function Node:add_view(view)
  assert(self.type == "leaf", "Tried to add view to non-leaf node")
  assert(not self.locked, "Tried to add view to locked node")
  if self.views[1] and self.views[1]:is(EmptyView) then
    table.remove(self.views)
  end
  table.insert(self.views, view)
  self:set_active_view(view)
end


function Node:set_active_view(view)
  assert(self.type == "leaf", "Tried to set active view on non-leaf node")
  self.active_view = view
  core.set_active_view(view)
end


function Node:get_view_idx(view)
  for i, v in ipairs(self.views) do
    if v == view then return i end
  end
end


function Node:get_node_for_view(view)
  for _, v in ipairs(self.views) do
    if v == view then return self end
  end
  if self.type ~= "leaf" then
    return self.a:get_node_for_view(view) or self.b:get_node_for_view(view)
  end
end


function Node:get_parent_node(root)
  if root.a == self or root.b == self then
    return root
  elseif root.type ~= "leaf" then
    return self:get_parent_node(root.a) or self:get_parent_node(root.b)
  end
end


function Node:get_children(t)
  t = t or {}
  for _, view in ipairs(self.views) do
    table.insert(t, view)
  end
  if self.a then self.a:get_children(t) end
  if self.b then self.b:get_children(t) end
  return t
end


function Node:get_divider_overlapping_point(px, py)
  if self.type ~= "leaf" then
    local p = 6
    local x, y, w, h = self:get_divider_rect()
    x, y = x - p, y - p
    w, h = w + p * 2, h + p * 2
    if px > x and py > y and px < x + w and py < y + h then
      return self
    end
    return self.a:get_divider_overlapping_point(px, py)
        or self.b:get_divider_overlapping_point(px, py)
  end
end


function Node:get_tab_overlapping_point(px, py)
  if #self.views == 1 then return nil end
  local x, y, w, h = self:get_tab_rect(1)
  if px >= x and py >= y and px < x + w * #self.views and py < y + h then
    return math.floor((px - x) / w) + 1
  end
end


function Node:get_child_overlapping_point(x, y)
  local child
  if self.type == "leaf" then
    return self
  elseif self.type == "hsplit" then
    child = (x < self.b.position.x) and self.a or self.b
  elseif self.type == "vsplit" then
    child = (y < self.b.position.y) and self.a or self.b
  end
  return child:get_child_overlapping_point(x, y)
end


function Node:get_tab_rect(idx)
  local tw = math.min(style.tab_width, math.ceil(self.size.x / #self.views))
  local h = style.font:get_height() + style.padding.y * 2
  return self.position.x + (idx-1) * tw, self.position.y, tw, h
end


function Node:get_divider_rect()
  local x, y = self.position.x, self.position.y
  if self.type == "hsplit" then
    return x + self.a.size.x, y, style.divider_size, self.size.y
  elseif self.type == "vsplit" then
    return x, y + self.a.size.y, self.size.x, style.divider_size
  end
end


function Node:get_locked_size()
  if self.type == "leaf" then
    if self.locked then
      local size = self.active_view.size
      return size.x, size.y
    end
  else
    local x1, y1 = self.a:get_locked_size()
    local x2, y2 = self.b:get_locked_size()
    if x1 and x2 then
      local dsx = (x1 < 1 or x2 < 1) and 0 or style.divider_size
      local dsy = (y1 < 1 or y2 < 1) and 0 or style.divider_size
      return x1 + x2 + dsx, y1 + y2 + dsy
    end
  end
end


local function copy_position_and_size(dst, src)
  dst.position.x, dst.position.y = src.position.x, src.position.y
  dst.size.x, dst.size.y = src.size.x, src.size.y
end


-- calculating the sizes is the same for hsplits and vsplits, except the x/y
-- axis are swapped; this function lets us use the same code for both
local function calc_split_sizes(self, x, y, x1, x2)
  local n
  local ds = (x1 and x1 < 1 or x2 and x2 < 1) and 0 or style.divider_size
  if x1 then
    n = x1 + ds
  elseif x2 then
    n = self.size[x] - x2
  else
    n = math.floor(self.size[x] * self.divider)
  end
  self.a.position[x] = self.position[x]
  self.a.position[y] = self.position[y]
  self.a.size[x] = n - ds
  self.a.size[y] = self.size[y]
  self.b.position[x] = self.position[x] + n
  self.b.position[y] = self.position[y]
  self.b.size[x] = self.size[x] - n
  self.b.size[y] = self.size[y]
end


function Node:update_layout()
  if self.type == "leaf" then
    local av = self.active_view
    if #self.views > 1 then
      local _, _, _, th = self:get_tab_rect(1)
      av.position.x, av.position.y = self.position.x, self.position.y + th
      av.size.x, av.size.y = self.size.x, self.size.y - th
    else
      copy_position_and_size(av, self)
    end
  else
    local x1, y1 = self.a:get_locked_size()
    local x2, y2 = self.b:get_locked_size()
    if self.type == "hsplit" then
      calc_split_sizes(self, "x", "y", x1, x2)
    elseif self.type == "vsplit" then
      calc_split_sizes(self, "y", "x", y1, y2)
    end
    self.a:update_layout()
    self.b:update_layout()
  end
end


function Node:update()
  if self.type == "leaf" then
    for _, view in ipairs(self.views) do
      view:update()
    end
  else
    self.a:update()
    self.b:update()
  end
end


function Node:draw_tabs()
  local x, y, _, h = self:get_tab_rect(1)
  local ds = style.divider_size
  core.push_clip_rect(x, y, self.size.x, h)
  renderer.draw_rect(x, y, self.size.x, h, style.background2)
  renderer.draw_rect(x, y + h - ds, self.size.x, ds, style.divider)

  for i, view in ipairs(self.views) do
    local x, y, w, h = self:get_tab_rect(i)
    local text = view:get_name()
    local color = style.dim
    if view == self.active_view then
      color = style.text
      renderer.draw_rect(x, y, w, h, style.background)
      renderer.draw_rect(x + w, y, ds, h, style.divider)
      renderer.draw_rect(x - ds, y, ds, h, style.divider)
    end
    if i == self.hovered_tab then
      color = style.text
    end
    core.push_clip_rect(x, y, w, h)
    x, w = x + style.padding.x, w - style.padding.x * 2
    local align = style.font:get_width(text) > w and "left" or "center"
    common.draw_text(style.font, color, text, align, x, y, w, h)
    core.pop_clip_rect()
  end

  core.pop_clip_rect()
end


function Node:draw()
  if self.type == "leaf" then
    if #self.views > 1 then
      self:draw_tabs()
    end
    local pos, size = self.active_view.position, self.active_view.size
    core.push_clip_rect(pos.x, pos.y, size.x + pos.x % 1, size.y + pos.y % 1)
    self.active_view:draw()
    core.pop_clip_rect()
  else
    local x, y, w, h = self:get_divider_rect()
    renderer.draw_rect(x, y, w, h, style.divider)
    self:propagate("draw")
  end
end



local RootView = View:extend()

function RootView:new()
  RootView.super.new(self)
  self.root_node = Node()
  self.deferred_draws = {}
  self.mouse = { x = 0, y = 0 }
end


function RootView:defer_draw(fn, ...)
  table.insert(self.deferred_draws, 1, { fn = fn, ... })
end


function RootView:get_active_node()
  return self.root_node:get_node_for_view(core.active_view)
end


function RootView:open_doc(doc)
  local node = self:get_active_node()
  if node.locked and core.last_active_view then
    core.set_active_view(core.last_active_view)
    node = self:get_active_node()
  end
  assert(not node.locked, "Cannot open doc on locked node")
  for i, view in ipairs(node.views) do
    if view.doc == doc then
      node:set_active_view(node.views[i])
      return view
    end
  end
  local view = DocView(doc)
  node:add_view(view)
  self.root_node:update_layout()
  view:scroll_to_line(view.doc:get_selection(), true, true)
  return view
end


function RootView:on_mouse_pressed(button, x, y, clicks)
  local div = self.root_node:get_divider_overlapping_point(x, y)
  if div then
    self.dragged_divider = div
    return
  end
  local node = self.root_node:get_child_overlapping_point(x, y)
  local idx = node:get_tab_overlapping_point(x, y)
  if idx then
    node:set_active_view(node.views[idx])
    if button == "middle" then
      node:close_active_view(self.root_node)
    end
  else
    core.set_active_view(node.active_view)
    node.active_view:on_mouse_pressed(button, x, y, clicks)
  end
end


function RootView:on_mouse_released(...)
  if self.dragged_divider then
    self.dragged_divider = nil
  end
  self.root_node:on_mouse_released(...)
end


function RootView:on_mouse_moved(x, y, dx, dy)
  if self.dragged_divider then
    local node = self.dragged_divider
    if node.type == "hsplit" then
      node.divider = node.divider + dx / node.size.x
    else
      node.divider = node.divider + dy / node.size.y
    end
    node.divider = common.clamp(node.divider, 0.01, 0.99)
    return
  end

  self.mouse.x, self.mouse.y = x, y
  self.root_node:on_mouse_moved(x, y, dx, dy)

  local node = self.root_node:get_child_overlapping_point(x, y)
  local div = self.root_node:get_divider_overlapping_point(x, y)
  if div then
    system.set_cursor(div.type == "hsplit" and "sizeh" or "sizev")
  elseif node:get_tab_overlapping_point(x, y) then
    system.set_cursor("arrow")
  else
    system.set_cursor(node.active_view.cursor)
  end
end


function RootView:on_mouse_wheel(...)
  local x, y = self.mouse.x, self.mouse.y
  local node = self.root_node:get_child_overlapping_point(x, y)
  node.active_view:on_mouse_wheel(...)
end


function RootView:on_text_input(...)
  core.active_view:on_text_input(...)
end


function RootView:update()
  copy_position_and_size(self.root_node, self)
  self.root_node:update()
  self.root_node:update_layout()
end


function RootView:draw()
  self.root_node:draw()
  while #self.deferred_draws > 0 do
    local t = table.remove(self.deferred_draws)
    t.fn(table.unpack(t))
  end
end


return RootView
end

do
local core = require "core"
local common = require "core.common"
local command = require "core.command"
local config = require "core.config"
local style = require "core.style"
local DocView = require "core.docview"
local LogView = require "core.logview"
local View = require "core.view"


local StatusView = View:extend()

StatusView.separator  = "      "
StatusView.separator2 = "   |   "


function StatusView:new()
  StatusView.super.new(self)
  self.message_timeout = 0
  self.message = {}
end


function StatusView:on_mouse_pressed()
  core.set_active_view(core.last_active_view)
  if system.get_time() < self.message_timeout
  and not core.active_view:is(LogView) then
    command.perform "core:open-log"
  end
end


function StatusView:show_message(icon, icon_color, text)
  self.message = {
    icon_color, style.icon_font, icon,
    style.dim, style.font, StatusView.separator2, style.text, text
  }
  self.message_timeout = system.get_time() + config.message_timeout
end


function StatusView:update()
  self.size.y = style.font:get_height() + style.padding.y * 2

  if system.get_time() < self.message_timeout then
    self.scroll.to.y = self.size.y
  else
    self.scroll.to.y = 0
  end

  StatusView.super.update(self)
end


local function draw_items(self, items, x, y, draw_fn)
  local font = style.font
  local color = style.text

  for _, item in ipairs(items) do
    if type(item) == "userdata" then
      font = item
    elseif type(item) == "table" then
      color = item
    else
      x = draw_fn(font, color, item, nil, x, y, 0, self.size.y)
    end
  end

  return x
end


local function text_width(font, _, text, _, x)
  return x + font:get_width(text)
end


function StatusView:draw_items(items, right_align, yoffset)
  local x, y = self:get_content_offset()
  y = y + (yoffset or 0)
  if right_align then
    local w = draw_items(self, items, 0, 0, text_width)
    x = x + self.size.x - w - style.padding.x
    draw_items(self, items, x, y, common.draw_text)
  else
    x = x + style.padding.x
    draw_items(self, items, x, y, common.draw_text)
  end
end


function StatusView:get_items()
  if getmetatable(core.active_view) == DocView then
    local dv = core.active_view
    local line, col = dv.doc:get_selection()
    local dirty = dv.doc:is_dirty()

    return {
      dirty and style.accent or style.text, style.icon_font, "f",
      style.dim, style.font, self.separator2, style.text,
      dv.doc.filename and style.text or style.dim, dv.doc:get_name(),
      style.text,
      self.separator,
      "line: ", line,
      self.separator,
      col > config.line_limit and style.accent or style.text, "col: ", col,
      style.text,
      self.separator,
      string.format("%d%%", line / #dv.doc.lines * 100),
    }, {
      style.icon_font, "g",
      style.font, style.dim, self.separator2, style.text,
      #dv.doc.lines, " lines",
      self.separator,
      dv.doc.crlf and "CRLF" or "LF"
    }
  end

  return {}, {
    style.icon_font, "g",
    style.font, style.dim, self.separator2,
    #core.docs, style.text, " / ",
    #core.project_files, " files"
  }
end


function StatusView:draw()
  self:draw_background(style.background2)

  if self.message then
    self:draw_items(self.message, false, self.size.y)
  end

  local left, right = self:get_items()
  self:draw_items(left)
  self:draw_items(right, true)
end


return StatusView
end

do
local strict = {}
strict.defined = {}


-- used to define a global variable
function global(t)
  for k, v in pairs(t) do
    strict.defined[k] = true
    rawset(_G, k, v)
  end
end


function strict.__newindex(t, k, v)
  error("cannot set undefined variable: " .. k, 2)
end


function strict.__index(t, k)
  if not strict.defined[k] then
    error("cannot get undefined variable: " .. k, 2)
  end
end


setmetatable(_G, strict)
end

do
local common = require "core.common"
local style = {}

style.padding = { x = common.round(14 * SCALE), y = common.round(7 * SCALE) }
style.divider_size = common.round(1 * SCALE)
style.scrollbar_size = common.round(4 * SCALE)
style.caret_width = common.round(2 * SCALE)
style.tab_width = common.round(170 * SCALE)

style.font = renderer.font.load(EXEDIR .. "/data/fonts/font.ttf", 14 * SCALE)
style.big_font = renderer.font.load(EXEDIR .. "/data/fonts/font.ttf", 34 * SCALE)
style.icon_font = renderer.font.load(EXEDIR .. "/data/fonts/icons.ttf", 14 * SCALE)
style.code_font = renderer.font.load(EXEDIR .. "/data/fonts/monospace.ttf", 13.5 * SCALE)

style.background = { common.color "#2e2e32" }
style.background2 = { common.color "#252529" }
style.background3 = { common.color "#252529" }
style.text = { common.color "#97979c" }
style.caret = { common.color "#93DDFA" }
style.accent = { common.color "#e1e1e6" }
style.dim = { common.color "#525257" }
style.divider = { common.color "#202024" }
style.selection = { common.color "#48484f" }
style.line_number = { common.color "#525259" }
style.line_number2 = { common.color "#83838f" }
style.line_highlight = { common.color "#343438" }
style.scrollbar = { common.color "#414146" }
style.scrollbar2 = { common.color "#4b4b52" }

style.syntax = {}
style.syntax["normal"] = { common.color "#e1e1e6" }
style.syntax["symbol"] = { common.color "#e1e1e6" }
style.syntax["comment"] = { common.color "#676b6f" }
style.syntax["keyword"] = { common.color "#E58AC9" }
style.syntax["keyword2"] = { common.color "#F77483" }
style.syntax["number"] = { common.color "#FFA94D" }
style.syntax["literal"] = { common.color "#FFA94D" }
style.syntax["string"] = { common.color "#f7c95c" }
style.syntax["operator"] = { common.color "#93DDFA" }
style.syntax["function"] = { common.color "#93DDFA" }

return style
end

do
local common = require "core.common"

local syntax = {}
syntax.items = {}

local plain_text_syntax = { patterns = {}, symbols = {} }


function syntax.add(t)
  table.insert(syntax.items, t)
end


local function find(string, field)
  for i = #syntax.items, 1, -1 do
    local t = syntax.items[i]
    if common.match_pattern(string, t[field] or {}) then
      return t
    end
  end
end

function syntax.get(filename, header)
  return find(filename, "files")
      or find(header, "headers")
      or plain_text_syntax
end


return syntax
end

do
local tokenizer = {}


local function push_token(t, type, text)
  local prev_type = t[#t-1]
  local prev_text = t[#t]
  if prev_type and (prev_type == type or prev_text:find("^%s*$")) then
    t[#t-1] = type
    t[#t] = prev_text .. text
  else
    table.insert(t, type)
    table.insert(t, text)
  end
end


local function is_escaped(text, idx, esc)
  local byte = esc:byte()
  local count = 0
  for i = idx - 1, 1, -1 do
    if text:byte(i) ~= byte then break end
    count = count + 1
  end
  return count % 2 == 1
end


local function find_non_escaped(text, pattern, offset, esc)
  while true do
    local s, e = text:find(pattern, offset)
    if not s then break end
    if esc and is_escaped(text, s, esc) then
      offset = e + 1
    else
      return s, e
    end
  end
end


function tokenizer.tokenize(syntax, text, state)
  local res = {}
  local i = 1

  if #syntax.patterns == 0 then
    return { "normal", text }
  end

  while i <= #text do
    -- continue trying to match the end pattern of a pair if we have a state set
    if state then
      local p = syntax.patterns[state]
      local s, e = find_non_escaped(text, p.pattern[2], i, p.pattern[3])

      if s then
        push_token(res, p.type, text:sub(i, e))
        state = nil
        i = e + 1
      else
        push_token(res, p.type, text:sub(i))
        break
      end
    end

    -- find matching pattern
    local matched = false
    for n, p in ipairs(syntax.patterns) do
      local pattern = (type(p.pattern) == "table") and p.pattern[1] or p.pattern
      local s, e = text:find("^" .. pattern, i)

      if s then
        -- matched pattern; make and add token
        local t = text:sub(s, e)
        push_token(res, syntax.symbols[t] or p.type, t)

        -- update state if this was a start|end pattern pair
        if type(p.pattern) == "table" then
          state = n
        end

        -- move cursor past this token
        i = e + 1
        matched = true
        break
      end
    end

    -- consume character if we didn't match
    if not matched then
      push_token(res, "normal", text:sub(i, i))
      i = i + 1
    end
  end

  return res, state
end


local function iter(t, i)
  i = i + 2
  local type, text = t[i], t[i+1]
  if type then
    return i, type, text
  end
end

function tokenizer.each_token(t)
  return iter, t, -1
end


return tokenizer
end

do
local core = require "core"
local config = require "core.config"
local style = require "core.style"
local common = require "core.common"
local Object = require "core.object"


local View = Object:extend()


function View:new()
  self.position = { x = 0, y = 0 }
  self.size = { x = 0, y = 0 }
  self.scroll = { x = 0, y = 0, to = { x = 0, y = 0 } }
  self.cursor = "arrow"
  self.scrollable = false
end


function View:move_towards(t, k, dest, rate)
  if type(t) ~= "table" then
    return self:move_towards(self, t, k, dest, rate)
  end
  local val = t[k]
  if math.abs(val - dest) < 0.5 then
    t[k] = dest
  else
    t[k] = common.lerp(val, dest, rate or 0.5)
  end
  if val ~= dest then
    core.redraw = true
  end
end


function View:try_close(do_close)
  do_close()
end


function View:get_name()
  return "---"
end


function View:get_scrollable_size()
  return math.huge
end


function View:get_scrollbar_rect()
  local sz = self:get_scrollable_size()
  if sz <= self.size.y or sz == math.huge then
    return 0, 0, 0, 0
  end
  local h = math.max(20, self.size.y * self.size.y / sz)
  return
    self.position.x + self.size.x - style.scrollbar_size,
    self.position.y + self.scroll.y * (self.size.y - h) / (sz - self.size.y),
    style.scrollbar_size,
    h
end


function View:scrollbar_overlaps_point(x, y)
  local sx, sy, sw, sh = self:get_scrollbar_rect()
  return x >= sx - sw * 3 and x < sx + sw and y >= sy and y < sy + sh
end


function View:on_mouse_pressed(button, x, y, clicks)
  if self:scrollbar_overlaps_point(x, y) then
    self.dragging_scrollbar = true
    return true
  end
end


function View:on_mouse_released(button, x, y)
  self.dragging_scrollbar = false
end


function View:on_mouse_moved(x, y, dx, dy)
  if self.dragging_scrollbar then
    local delta = self:get_scrollable_size() / self.size.y * dy
    self.scroll.to.y = self.scroll.to.y + delta
  end
  self.hovered_scrollbar = self:scrollbar_overlaps_point(x, y)
end


function View:on_text_input(text)
  -- no-op
end


function View:on_mouse_wheel(y)
  if self.scrollable then
    self.scroll.to.y = self.scroll.to.y + y * -config.mouse_wheel_scroll
  end
end


function View:get_content_bounds()
  local x = self.scroll.x
  local y = self.scroll.y
  return x, y, x + self.size.x, y + self.size.y
end


function View:get_content_offset()
  local x = common.round(self.position.x - self.scroll.x)
  local y = common.round(self.position.y - self.scroll.y)
  return x, y
end


function View:clamp_scroll_position()
  local max = self:get_scrollable_size() - self.size.y
  self.scroll.to.y = common.clamp(self.scroll.to.y, 0, max)
end


function View:update()
  self:clamp_scroll_position()
  self:move_towards(self.scroll, "x", self.scroll.to.x, 0.3)
  self:move_towards(self.scroll, "y", self.scroll.to.y, 0.3)
end


function View:draw_background(color)
  local x, y = self.position.x, self.position.y
  local w, h = self.size.x, self.size.y
  renderer.draw_rect(x, y, w + x % 1, h + y % 1, color)
end


function View:draw_scrollbar()
  local x, y, w, h = self:get_scrollbar_rect()
  local highlight = self.hovered_scrollbar or self.dragging_scrollbar
  local color = highlight and style.scrollbar2 or style.scrollbar
  renderer.draw_rect(x, y, w, h, color)
end


function View:draw()
end


return View
end

do
local core = require "core"
local command = require "core.command"
local CommandView = require "core.commandview"

local function has_commandview()
  return core.active_view:is(CommandView)
end


command.add(has_commandview, {
  ["command:submit"] = function()
    core.active_view:submit()
  end,

  ["command:complete"] = function()
    core.active_view:complete()
  end,

  ["command:escape"] = function()
    core.active_view:exit()
  end,

  ["command:select-previous"] = function()
    core.active_view:move_suggestion_idx(1)
  end,

  ["command:select-next"] = function()
    core.active_view:move_suggestion_idx(-1)
  end,
})
end

do
local core = require "core"
local common = require "core.common"
local command = require "core.command"
local keymap = require "core.keymap"
local LogView = require "core.logview"


local fullscreen = false

command.add(nil, {
  ["core:quit"] = function()
    core.quit()
  end,

  ["core:force-quit"] = function()
    core.quit(true)
  end,

  ["core:toggle-fullscreen"] = function()
    fullscreen = not fullscreen
    system.set_window_mode(fullscreen and "fullscreen" or "normal")
  end,

  ["core:reload-module"] = function()
    core.command_view:enter("Reload Module", function(text, item)
      local text = item and item.text or text
      core.reload_module(text)
      core.log("Reloaded module %q", text)
    end, function(text)
      local items = {}
      for name in pairs(package.loaded) do
        table.insert(items, name)
      end
      return common.fuzzy_match(items, text)
    end)
  end,

  ["core:find-command"] = function()
    local commands = command.get_all_valid()
    core.command_view:enter("Do Command", function(text, item)
      if item then
        command.perform(item.command)
      end
    end, function(text)
      local res = common.fuzzy_match(commands, text)
      for i, name in ipairs(res) do
        res[i] = {
          text = command.prettify_name(name),
          info = keymap.get_binding(name),
          command = name,
        }
      end
      return res
    end)
  end,

  ["core:find-file"] = function()
    core.command_view:enter("Open File From Project", function(text, item)
      text = item and item.text or text
      core.root_view:open_doc(core.open_doc(text))
    end, function(text)
      local files = {}
      for _, item in pairs(core.project_files) do
        if item.type == "file" then
          table.insert(files, item.filename)
        end
      end
      return common.fuzzy_match(files, text)
    end)
  end,

  ["core:new-doc"] = function()
    core.root_view:open_doc(core.open_doc())
  end,

  ["core:open-file"] = function()
    core.command_view:enter("Open File", function(text)
      core.root_view:open_doc(core.open_doc(text))
    end, common.path_suggest)
  end,

  ["core:open-log"] = function()
    local node = core.root_view:get_active_node()
    node:add_view(LogView())
  end,

  ["core:open-user-module"] = function()
    core.root_view:open_doc(core.open_doc(EXEDIR .. "/data/user/init.lua"))
  end,

  ["core:open-project-module"] = function()
    local filename = ".lite_project.lua"
    if system.get_file_info(filename) then
      core.root_view:open_doc(core.open_doc(filename))
    else
      local doc = core.open_doc()
      core.root_view:open_doc(doc)
      doc:save(filename)
    end
  end,
})
end

do
local core = require "core"
local command = require "core.command"
local common = require "core.common"
local config = require "core.config"
local translate = require "core.doc.translate"
local DocView = require "core.docview"


local function dv()
  return core.active_view
end


local function doc()
  return core.active_view.doc
end


local function get_indent_string()
  if config.tab_type == "hard" then
    return "\t"
  end
  return string.rep(" ", config.indent_size)
end


local function insert_at_start_of_selected_lines(text, skip_empty)
  local line1, col1, line2, col2, swap = doc():get_selection(true)
  for line = line1, line2 do
    local line_text = doc().lines[line]
    if (not skip_empty or line_text:find("%S")) then
      doc():insert(line, 1, text)
    end
  end
  doc():set_selection(line1, col1 + #text, line2, col2 + #text, swap)
end


local function remove_from_start_of_selected_lines(text, skip_empty)
  local line1, col1, line2, col2, swap = doc():get_selection(true)
  for line = line1, line2 do
    local line_text = doc().lines[line]
    if  line_text:sub(1, #text) == text
    and (not skip_empty or line_text:find("%S"))
    then
      doc():remove(line, 1, line, #text + 1)
    end
  end
  doc():set_selection(line1, col1 - #text, line2, col2 - #text, swap)
end


local function append_line_if_last_line(line)
  if line >= #doc().lines then
    doc():insert(line, math.huge, "\n")
  end
end


local function save(filename)
  doc():save(filename)
  core.log("Saved \"%s\"", doc().filename)
end


local commands = {
  ["doc:undo"] = function()
    doc():undo()
  end,

  ["doc:redo"] = function()
    doc():redo()
  end,

  ["doc:cut"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    end
  end,

  ["doc:copy"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
    end
  end,

  ["doc:paste"] = function()
    doc():text_input(system.get_clipboard():gsub("\r", ""))
  end,

  ["doc:newline"] = function()
    local line, col = doc():get_selection()
    local indent = doc().lines[line]:match("^[\t ]*")
    if col <= #indent then
      indent = indent:sub(#indent + 2 - col)
    end
    doc():text_input("\n" .. indent)
  end,

  ["doc:newline-below"] = function()
    local line = doc():get_selection()
    local indent = doc().lines[line]:match("^[\t ]*")
    doc():insert(line, math.huge, "\n" .. indent)
    doc():set_selection(line + 1, math.huge)
  end,

  ["doc:newline-above"] = function()
    local line = doc():get_selection()
    local indent = doc().lines[line]:match("^[\t ]*")
    doc():insert(line, 1, indent .. "\n")
    doc():set_selection(line, math.huge)
  end,

  ["doc:delete"] = function()
    local line, col = doc():get_selection()
    if not doc():has_selection() and doc().lines[line]:find("^%s*$", col) then
      doc():remove(line, col, line, math.huge)
    end
    doc():delete_to(translate.next_char)
  end,

  ["doc:backspace"] = function()
    local line, col = doc():get_selection()
    if not doc():has_selection() then
      local text = doc():get_text(line, 1, line, col)
      if #text >= config.indent_size and text:find("^ *$") then
        doc():delete_to(0, -config.indent_size)
        return
      end
    end
    doc():delete_to(translate.previous_char)
  end,

  ["doc:select-all"] = function()
    doc():set_selection(1, 1, math.huge, math.huge)
  end,

  ["doc:select-none"] = function()
    local line, col = doc():get_selection()
    doc():set_selection(line, col)
  end,

  ["doc:select-lines"] = function()
    local line1, _, line2, _, swap = doc():get_selection(true)
    append_line_if_last_line(line2)
    doc():set_selection(line1, 1, line2 + 1, 1, swap)
  end,

  ["doc:select-word"] = function()
    local line1, col1 = doc():get_selection(true)
    local line1, col1 = translate.start_of_word(doc(), line1, col1)
    local line2, col2 = translate.end_of_word(doc(), line1, col1)
    doc():set_selection(line2, col2, line1, col1)
  end,

  ["doc:join-lines"] = function()
    local line1, _, line2 = doc():get_selection(true)
    if line1 == line2 then line2 = line2 + 1 end
    local text = doc():get_text(line1, 1, line2, math.huge)
    text = text:gsub("(.-)\n[\t ]*", function(x)
      return x:find("^%s*$") and x or x .. " "
    end)
    doc():insert(line1, 1, text)
    doc():remove(line1, #text + 1, line2, math.huge)
    if doc():has_selection() then
      doc():set_selection(line1, math.huge)
    end
  end,

  ["doc:indent"] = function()
    local text = get_indent_string()
    if doc():has_selection() then
      insert_at_start_of_selected_lines(text)
    else
      doc():text_input(text)
    end
  end,

  ["doc:unindent"] = function()
    local text = get_indent_string()
    remove_from_start_of_selected_lines(text)
  end,

  ["doc:duplicate-lines"] = function()
    local line1, col1, line2, col2, swap = doc():get_selection(true)
    append_line_if_last_line(line2)
    local text = doc():get_text(line1, 1, line2 + 1, 1)
    doc():insert(line2 + 1, 1, text)
    local n = line2 - line1 + 1
    doc():set_selection(line1 + n, col1, line2 + n, col2, swap)
  end,

  ["doc:delete-lines"] = function()
    local line1, col1, line2 = doc():get_selection(true)
    append_line_if_last_line(line2)
    doc():remove(line1, 1, line2 + 1, 1)
    doc():set_selection(line1, col1)
  end,

  ["doc:move-lines-up"] = function()
    local line1, col1, line2, col2, swap = doc():get_selection(true)
    append_line_if_last_line(line2)
    if line1 > 1 then
      local text = doc().lines[line1 - 1]
      doc():insert(line2 + 1, 1, text)
      doc():remove(line1 - 1, 1, line1, 1)
      doc():set_selection(line1 - 1, col1, line2 - 1, col2, swap)
    end
  end,

  ["doc:move-lines-down"] = function()
    local line1, col1, line2, col2, swap = doc():get_selection(true)
    append_line_if_last_line(line2 + 1)
    if line2 < #doc().lines then
      local text = doc().lines[line2 + 1]
      doc():remove(line2 + 1, 1, line2 + 2, 1)
      doc():insert(line1, 1, text)
      doc():set_selection(line1 + 1, col1, line2 + 1, col2, swap)
    end
  end,

  ["doc:toggle-line-comments"] = function()
    local comment = doc().syntax.comment
    if not comment then return end
    local comment_text = comment .. " "
    local line1, _, line2 = doc():get_selection(true)
    local uncomment = true
    for line = line1, line2 do
      local text = doc().lines[line]
      if text:find("%S") and text:find(comment_text, 1, true) ~= 1 then
        uncomment = false
      end
    end
    if uncomment then
      remove_from_start_of_selected_lines(comment_text, true)
    else
      insert_at_start_of_selected_lines(comment_text, true)
    end
  end,

  ["doc:upper-case"] = function()
    doc():replace(string.upper)
  end,

  ["doc:lower-case"] = function()
    doc():replace(string.lower)
  end,

  ["doc:go-to-line"] = function()
    local dv = dv()

    local items
    local function init_items()
      if items then return end
      items = {}
      local mt = { __tostring = function(x) return x.text end }
      for i, line in ipairs(dv.doc.lines) do
        local item = { text = line:sub(1, -2), line = i, info = "line: " .. i }
        table.insert(items, setmetatable(item, mt))
      end
    end

    core.command_view:enter("Go To Line", function(text, item)
      local line = item and item.line or tonumber(text)
      if not line then
        core.error("Invalid line number or unmatched string")
        return
      end
      dv.doc:set_selection(line, 1  )
      dv:scroll_to_line(line, true)

    end, function(text)
      if not text:find("^%d*$") then
        init_items()
        return common.fuzzy_match(items, text)
      end
    end)
  end,

  ["doc:toggle-line-ending"] = function()
    doc().crlf = not doc().crlf
  end,

  ["doc:save-as"] = function()
    if doc().filename then
      core.command_view:set_text(doc().filename)
    end
    core.command_view:enter("Save As", function(filename)
      save(filename)
    end, common.path_suggest)
  end,

  ["doc:save"] = function()
    if doc().filename then
      save()
    else
      command.perform("doc:save-as")
    end
  end,

  ["doc:rename"] = function()
    local old_filename = doc().filename
    if not old_filename then
      core.error("Cannot rename unsaved doc")
      return
    end
    core.command_view:set_text(old_filename)
    core.command_view:enter("Rename", function(filename)
      doc():save(filename)
      core.log("Renamed \"%s\" to \"%s\"", old_filename, filename)
      if filename ~= old_filename then
        os.remove(old_filename)
      end
    end, common.path_suggest)
  end,
}


local translations = {
  ["previous-char"] = translate.previous_char,
  ["next-char"] = translate.next_char,
  ["previous-word-start"] = translate.previous_word_start,
  ["next-word-end"] = translate.next_word_end,
  ["previous-block-start"] = translate.previous_block_start,
  ["next-block-end"] = translate.next_block_end,
  ["start-of-doc"] = translate.start_of_doc,
  ["end-of-doc"] = translate.end_of_doc,
  ["start-of-line"] = translate.start_of_line,
  ["end-of-line"] = translate.end_of_line,
  ["start-of-word"] = translate.start_of_word,
  ["end-of-word"] = translate.end_of_word,
  ["previous-line"] = DocView.translate.previous_line,
  ["next-line"] = DocView.translate.next_line,
  ["previous-page"] = DocView.translate.previous_page,
  ["next-page"] = DocView.translate.next_page,
}

for name, fn in pairs(translations) do
  commands["doc:move-to-" .. name] = function() doc():move_to(fn, dv()) end
  commands["doc:select-to-" .. name] = function() doc():select_to(fn, dv()) end
  commands["doc:delete-to-" .. name] = function() doc():delete_to(fn, dv()) end
end

commands["doc:move-to-previous-char"] = function()
  if doc():has_selection() then
    local line, col = doc():get_selection(true)
    doc():set_selection(line, col)
  else
    doc():move_to(translate.previous_char)
  end
end

commands["doc:move-to-next-char"] = function()
  if doc():has_selection() then
    local _, _, line, col = doc():get_selection(true)
    doc():set_selection(line, col)
  else
    doc():move_to(translate.next_char)
  end
end

command.add("core.docview", commands)
end

do
local core = require "core"
local command = require "core.command"
local config = require "core.config"
local search = require "core.doc.search"
local DocView = require "core.docview"

local max_previous_finds = 50


local function doc()
  return core.active_view.doc
end


local previous_finds
local last_doc
local last_fn, last_text


local function push_previous_find(doc, sel)
  if last_doc ~= doc then
    last_doc = doc
    previous_finds = {}
  end
  if #previous_finds >= max_previous_finds then
    table.remove(previous_finds, 1)
  end
  table.insert(previous_finds, sel or { doc:get_selection() })
end


local function find(label, search_fn)
  local dv = core.active_view
  local sel = { dv.doc:get_selection() }
  local text = dv.doc:get_text(table.unpack(sel))
  local found = false

  core.command_view:set_text(text, true)

  core.command_view:enter(label, function(text)
    if found then
      last_fn, last_text = search_fn, text
      previous_finds = {}
      push_previous_find(dv.doc, sel)
    else
      core.error("Couldn't find %q", text)
      dv.doc:set_selection(table.unpack(sel))
      dv:scroll_to_make_visible(sel[1], sel[2])
    end

  end, function(text)
    local ok, line1, col1, line2, col2 = pcall(search_fn, dv.doc, sel[1], sel[2], text)
    if ok and line1 and text ~= "" then
      dv.doc:set_selection(line2, col2, line1, col1)
      dv:scroll_to_line(line2, true)
      found = true
    else
      dv.doc:set_selection(table.unpack(sel))
      found = false
    end

  end, function(explicit)
    if explicit then
      dv.doc:set_selection(table.unpack(sel))
      dv:scroll_to_make_visible(sel[1], sel[2])
    end
  end)
end


local function replace(kind, default, fn)
  core.command_view:set_text(default, true)

  core.command_view:enter("Find To Replace " .. kind, function(old)
    core.command_view:set_text(old, true)

    local s = string.format("Replace %s %q With", kind, old)
    core.command_view:enter(s, function(new)
      local n = doc():replace(function(text)
        return fn(text, old, new)
      end)
      core.log("Replaced %d instance(s) of %s %q with %q", n, kind, old, new)
    end)
  end)
end


local function has_selection()
  return core.active_view:is(DocView)
     and core.active_view.doc:has_selection()
end

command.add(has_selection, {
  ["find-replace:select-next"] = function()
    local l1, c1, l2, c2 = doc():get_selection(true)
    local text = doc():get_text(l1, c1, l2, c2)
    local l1, c1, l2, c2 = search.find(doc(), l2, c2, text, { wrap = true })
    if l2 then doc():set_selection(l2, c2, l1, c1) end
  end
})

command.add("core.docview", {
  ["find-replace:find"] = function()
    find("Find Text", function(doc, line, col, text)
      local opt = { wrap = true, no_case = true }
      return search.find(doc, line, col, text, opt)
    end)
  end,

  ["find-replace:find-pattern"] = function()
    find("Find Text Pattern", function(doc, line, col, text)
      local opt = { wrap = true, no_case = true, pattern = true }
      return search.find(doc, line, col, text, opt)
    end)
  end,

  ["find-replace:repeat-find"] = function()
    if not last_fn then
      core.error("No find to continue from")
    else
      local line, col = doc():get_selection()
      local line1, col1, line2, col2 = last_fn(doc(), line, col, last_text)
      if line1 then
        push_previous_find(doc())
        doc():set_selection(line2, col2, line1, col1)
        core.active_view:scroll_to_line(line2, true)
      end
    end
  end,

  ["find-replace:previous-find"] = function()
    local sel = table.remove(previous_finds)
    if not sel or doc() ~= last_doc then
      core.error("No previous finds")
      return
    end
    doc():set_selection(table.unpack(sel))
    core.active_view:scroll_to_line(sel[3], true)
  end,

  ["find-replace:replace"] = function()
    replace("Text", "", function(text, old, new)
      return text:gsub(old:gsub("%W", "%%%1"), new:gsub("%%", "%%%%"), nil)
    end)
  end,

  ["find-replace:replace-pattern"] = function()
    replace("Pattern", "", function(text, old, new)
      return text:gsub(old, new)
    end)
  end,

  ["find-replace:replace-symbol"] = function()
    local first = ""
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      first = text:match(config.symbol_pattern) or ""
    end
    replace("Symbol", first, function(text, old, new)
      local n = 0
      local res = text:gsub(config.symbol_pattern, function(sym)
        if old == sym then
          n = n + 1
          return new
        end
      end)
      return res, n
    end)
  end,
})
end

do
local core = require "core"
local style = require "core.style"
local DocView = require "core.docview"
local command = require "core.command"
local common = require "core.common"


local t = {
  ["root:close"] = function()
    local node = core.root_view:get_active_node()
    node:close_active_view(core.root_view.root_node)
  end,

  ["root:switch-to-previous-tab"] = function()
    local node = core.root_view:get_active_node()
    local idx = node:get_view_idx(core.active_view)
    idx = idx - 1
    if idx < 1 then idx = #node.views end
    node:set_active_view(node.views[idx])
  end,

  ["root:switch-to-next-tab"] = function()
    local node = core.root_view:get_active_node()
    local idx = node:get_view_idx(core.active_view)
    idx = idx + 1
    if idx > #node.views then idx = 1 end
    node:set_active_view(node.views[idx])
  end,

  ["root:move-tab-left"] = function()
    local node = core.root_view:get_active_node()
    local idx = node:get_view_idx(core.active_view)
    if idx > 1 then
      table.remove(node.views, idx)
      table.insert(node.views, idx - 1, core.active_view)
    end
  end,

  ["root:move-tab-right"] = function()
    local node = core.root_view:get_active_node()
    local idx = node:get_view_idx(core.active_view)
    if idx < #node.views then
      table.remove(node.views, idx)
      table.insert(node.views, idx + 1, core.active_view)
    end
  end,

  ["root:shrink"] = function()
    local node = core.root_view:get_active_node()
    local parent = node:get_parent_node(core.root_view.root_node)
    local n = (parent.a == node) and -0.1 or 0.1
    parent.divider = common.clamp(parent.divider + n, 0.1, 0.9)
  end,

  ["root:grow"] = function()
    local node = core.root_view:get_active_node()
    local parent = node:get_parent_node(core.root_view.root_node)
    local n = (parent.a == node) and 0.1 or -0.1
    parent.divider = common.clamp(parent.divider + n, 0.1, 0.9)
  end,
}


for i = 1, 9 do
  t["root:switch-to-tab-" .. i] = function()
    local node = core.root_view:get_active_node()
    local view = node.views[i]
    if view then
      node:set_active_view(view)
    end
  end
end


for _, dir in ipairs { "left", "right", "up", "down" } do
  t["root:split-" .. dir] = function()
    local node = core.root_view:get_active_node()
    local av = node.active_view
    node:split(dir)
    if av:is(DocView) then
      core.root_view:open_doc(av.doc)
    end
  end

  t["root:switch-to-" .. dir] = function()
    local node = core.root_view:get_active_node()
    local x, y
    if dir == "left" or dir == "right" then
      y = node.position.y + node.size.y / 2
      x = node.position.x + (dir == "left" and -1 or node.size.x + style.divider_size)
    else
      x = node.position.x + node.size.x / 2
      y = node.position.y + (dir == "up"   and -1 or node.size.y + style.divider_size)
    end
    local node = core.root_view.root_node:get_child_overlapping_point(x, y)
    if not node:get_locked_size() then
      core.set_active_view(node.active_view)
    end
  end
end

command.add(function()
  local node = core.root_view:get_active_node()
  return not node:get_locked_size()
end, t)
end

do
local core = require "core"
local config = require "core.config"
local tokenizer = require "core.tokenizer"
local Object = require "core.object"


local Highlighter = Object:extend()


function Highlighter:new(doc)
  self.doc = doc
  self:reset()

  -- init incremental syntax highlighting
  core.add_thread(function()
    while true do
      if self.first_invalid_line > self.max_wanted_line then
        self.max_wanted_line = 0
        coroutine.yield(1 / config.fps)

      else
        local max = math.min(self.first_invalid_line + 40, self.max_wanted_line)

        for i = self.first_invalid_line, max do
          local state = (i > 1) and self.lines[i - 1].state
          local line = self.lines[i]
          if not (line and line.init_state == state) then
            self.lines[i] = self:tokenize_line(i, state)
          end
        end

        self.first_invalid_line = max + 1
        core.redraw = true
        coroutine.yield()
      end
    end
  end, self)
end


function Highlighter:reset()
  self.lines = {}
  self.first_invalid_line = 1
  self.max_wanted_line = 0
end


function Highlighter:invalidate(idx)
  self.first_invalid_line = math.min(self.first_invalid_line, idx)
  self.max_wanted_line = math.min(self.max_wanted_line, #self.doc.lines)
end


function Highlighter:tokenize_line(idx, state)
  local res = {}
  res.init_state = state
  res.text = self.doc.lines[idx]
  res.tokens, res.state = tokenizer.tokenize(self.doc.syntax, res.text, state)
  return res
end


function Highlighter:get_line(idx)
  local line = self.lines[idx]
  if not line or line.text ~= self.doc.lines[idx] then
    local prev = self.lines[idx - 1]
    line = self:tokenize_line(idx, prev and prev.state)
    self.lines[idx] = line
  end
  self.max_wanted_line = math.max(self.max_wanted_line, idx)
  return line
end


function Highlighter:each_token(idx)
  return tokenizer.each_token(self:get_line(idx).tokens)
end


return Highlighter
end

do
local Object = require "core.object"
local Highlighter = require "core.doc.highlighter"
local syntax = require "core.syntax"
local config = require "core.config"
local common = require "core.common"


local Doc = Object:extend()


local function split_lines(text)
  local res = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(res, line)
  end
  return res
end


local function splice(t, at, remove, insert)
  insert = insert or {}
  local offset = #insert - remove
  local old_len = #t
  if offset < 0 then
    for i = at - offset, old_len - offset do
      t[i + offset] = t[i]
    end
  elseif offset > 0 then
    for i = old_len, at, -1 do
      t[i + offset] = t[i]
    end
  end
  for i, item in ipairs(insert) do
    t[at + i - 1] = item
  end
end


function Doc:new(filename)
  self:reset()
  if filename then
    self:load(filename)
  end
end


function Doc:reset()
  self.lines = { "\n" }
  self.selection = { a = { line=1, col=1 }, b = { line=1, col=1 } }
  self.undo_stack = { idx = 1 }
  self.redo_stack = { idx = 1 }
  self.clean_change_id = 1
  self.highlighter = Highlighter(self)
  self:reset_syntax()
end


function Doc:reset_syntax()
  local header = self:get_text(1, 1, self:position_offset(1, 1, 128))
  local syn = syntax.get(self.filename or "", header)
  if self.syntax ~= syn then
    self.syntax = syn
    self.highlighter:reset()
  end
end


function Doc:load(filename)
  local fp = assert( io.open(filename, "rb") )
  self:reset()
  self.filename = filename
  self.lines = {}
  for line in fp:lines() do
    if line:byte(-1) == 13 then
      line = line:sub(1, -2)
      self.crlf = true
    end
    table.insert(self.lines, line .. "\n")
  end
  if #self.lines == 0 then
    table.insert(self.lines, "\n")
  end
  fp:close()
  self:reset_syntax()
end


function Doc:save(filename)
  filename = filename or assert(self.filename, "no filename set to default to")
  local fp = assert( io.open(filename, "wb") )
  for _, line in ipairs(self.lines) do
    if self.crlf then line = line:gsub("\n", "\r\n") end
    fp:write(line)
  end
  fp:close()
  self.filename = filename or self.filename
  self:reset_syntax()
  self:clean()
end


function Doc:get_name()
  return self.filename or "unsaved"
end


function Doc:is_dirty()
  return self.clean_change_id ~= self:get_change_id()
end


function Doc:clean()
  self.clean_change_id = self:get_change_id()
end


function Doc:get_change_id()
  return self.undo_stack.idx
end


function Doc:set_selection(line1, col1, line2, col2, swap)
  assert(not line2 == not col2, "expected 2 or 4 arguments")
  if swap then line1, col1, line2, col2 = line2, col2, line1, col1 end
  line1, col1 = self:sanitize_position(line1, col1)
  line2, col2 = self:sanitize_position(line2 or line1, col2 or col1)
  self.selection.a.line, self.selection.a.col = line1, col1
  self.selection.b.line, self.selection.b.col = line2, col2
end


local function sort_positions(line1, col1, line2, col2)
  if line1 > line2
  or line1 == line2 and col1 > col2 then
    return line2, col2, line1, col1, true
  end
  return line1, col1, line2, col2, false
end


function Doc:get_selection(sort)
  local a, b = self.selection.a, self.selection.b
  if sort then
    return sort_positions(a.line, a.col, b.line, b.col)
  end
  return a.line, a.col, b.line, b.col
end


function Doc:has_selection()
  local a, b = self.selection.a, self.selection.b
  return not (a.line == b.line and a.col == b.col)
end


function Doc:sanitize_selection()
  self:set_selection(self:get_selection())
end


function Doc:sanitize_position(line, col)
  line = common.clamp(line, 1, #self.lines)
  col = common.clamp(col, 1, #self.lines[line])
  return line, col
end


local function position_offset_func(self, line, col, fn, ...)
  line, col = self:sanitize_position(line, col)
  return fn(self, line, col, ...)
end


local function position_offset_byte(self, line, col, offset)
  line, col = self:sanitize_position(line, col)
  col = col + offset
  while line > 1 and col < 1 do
    line = line - 1
    col = col + #self.lines[line]
  end
  while line < #self.lines and col > #self.lines[line] do
    col = col - #self.lines[line]
    line = line + 1
  end
  return self:sanitize_position(line, col)
end


local function position_offset_linecol(self, line, col, lineoffset, coloffset)
  return self:sanitize_position(line + lineoffset, col + coloffset)
end


function Doc:position_offset(line, col, ...)
  if type(...) ~= "number" then
    return position_offset_func(self, line, col, ...)
  elseif select("#", ...) == 1 then
    return position_offset_byte(self, line, col, ...)
  elseif select("#", ...) == 2 then
    return position_offset_linecol(self, line, col, ...)
  else
    error("bad number of arguments")
  end
end


function Doc:get_text(line1, col1, line2, col2)
  line1, col1 = self:sanitize_position(line1, col1)
  line2, col2 = self:sanitize_position(line2, col2)
  line1, col1, line2, col2 = sort_positions(line1, col1, line2, col2)
  if line1 == line2 then
    return self.lines[line1]:sub(col1, col2 - 1)
  end
  local lines = { self.lines[line1]:sub(col1) }
  for i = line1 + 1, line2 - 1 do
    table.insert(lines, self.lines[i])
  end
  table.insert(lines, self.lines[line2]:sub(1, col2 - 1))
  return table.concat(lines)
end


function Doc:get_char(line, col)
  line, col = self:sanitize_position(line, col)
  return self.lines[line]:sub(col, col)
end


local function push_undo(undo_stack, time, type, ...)
  undo_stack[undo_stack.idx] = { type = type, time = time, ... }
  undo_stack[undo_stack.idx - config.max_undos] = nil
  undo_stack.idx = undo_stack.idx + 1
end


local function pop_undo(self, undo_stack, redo_stack)
  -- pop command
  local cmd = undo_stack[undo_stack.idx - 1]
  if not cmd then return end
  undo_stack.idx = undo_stack.idx - 1

  -- handle command
  if cmd.type == "insert" then
    local line, col, text = table.unpack(cmd)
    self:raw_insert(line, col, text, redo_stack, cmd.time)

  elseif cmd.type == "remove" then
    local line1, col1, line2, col2 = table.unpack(cmd)
    self:raw_remove(line1, col1, line2, col2, redo_stack, cmd.time)

  elseif cmd.type == "selection" then
    self.selection.a.line, self.selection.a.col = cmd[1], cmd[2]
    self.selection.b.line, self.selection.b.col = cmd[3], cmd[4]
  end

  -- if next undo command is within the merge timeout then treat as a single
  -- command and continue to execute it
  local next = undo_stack[undo_stack.idx - 1]
  if next and math.abs(cmd.time - next.time) < config.undo_merge_timeout then
    return pop_undo(self, undo_stack, redo_stack)
  end
end


function Doc:raw_insert(line, col, text, undo_stack, time)
  -- split text into lines and merge with line at insertion point
  local lines = split_lines(text)
  local before = self.lines[line]:sub(1, col - 1)
  local after = self.lines[line]:sub(col)
  for i = 1, #lines - 1 do
    lines[i] = lines[i] .. "\n"
  end
  lines[1] = before .. lines[1]
  lines[#lines] = lines[#lines] .. after

  -- splice lines into line array
  splice(self.lines, line, 1, lines)

  -- push undo
  local line2, col2 = self:position_offset(line, col, #text)
  push_undo(undo_stack, time, "selection", self:get_selection())
  push_undo(undo_stack, time, "remove", line, col, line2, col2)

  -- update highlighter and assure selection is in bounds
  self.highlighter:invalidate(line)
  self:sanitize_selection()
end


function Doc:raw_remove(line1, col1, line2, col2, undo_stack, time)
  -- push undo
  local text = self:get_text(line1, col1, line2, col2)
  push_undo(undo_stack, time, "selection", self:get_selection())
  push_undo(undo_stack, time, "insert", line1, col1, text)

  -- get line content before/after removed text
  local before = self.lines[line1]:sub(1, col1 - 1)
  local after = self.lines[line2]:sub(col2)

  -- splice line into line array
  splice(self.lines, line1, line2 - line1 + 1, { before .. after })

  -- update highlighter and assure selection is in bounds
  self.highlighter:invalidate(line1)
  self:sanitize_selection()
end


function Doc:insert(line, col, text)
  self.redo_stack = { idx = 1 }
  line, col = self:sanitize_position(line, col)
  self:raw_insert(line, col, text, self.undo_stack, system.get_time())
end


function Doc:remove(line1, col1, line2, col2)
  self.redo_stack = { idx = 1 }
  line1, col1 = self:sanitize_position(line1, col1)
  line2, col2 = self:sanitize_position(line2, col2)
  line1, col1, line2, col2 = sort_positions(line1, col1, line2, col2)
  self:raw_remove(line1, col1, line2, col2, self.undo_stack, system.get_time())
end


function Doc:undo()
  pop_undo(self, self.undo_stack, self.redo_stack)
end


function Doc:redo()
  pop_undo(self, self.redo_stack, self.undo_stack)
end


function Doc:text_input(text)
  if self:has_selection() then
    self:delete_to()
  end
  local line, col = self:get_selection()
  self:insert(line, col, text)
  self:move_to(#text)
end


function Doc:replace(fn)
  local line1, col1, line2, col2, swap
  local had_selection = self:has_selection()
  if had_selection then
    line1, col1, line2, col2, swap = self:get_selection(true)
  else
    line1, col1, line2, col2 = 1, 1, #self.lines, #self.lines[#self.lines]
  end
  local old_text = self:get_text(line1, col1, line2, col2)
  local new_text, n = fn(old_text)
  if old_text ~= new_text then
    self:insert(line2, col2, new_text)
    self:remove(line1, col1, line2, col2)
    if had_selection then
      line2, col2 = self:position_offset(line1, col1, #new_text)
      self:set_selection(line1, col1, line2, col2, swap)
    end
  end
  return n
end


function Doc:delete_to(...)
  local line, col = self:get_selection(true)
  if self:has_selection() then
    self:remove(self:get_selection())
  else
    local line2, col2 = self:position_offset(line, col, ...)
    self:remove(line, col, line2, col2)
    line, col = sort_positions(line, col, line2, col2)
  end
  self:set_selection(line, col)
end


function Doc:move_to(...)
  local line, col = self:get_selection()
  self:set_selection(self:position_offset(line, col, ...))
end


function Doc:select_to(...)
  local line, col, line2, col2 = self:get_selection()
  line, col = self:position_offset(line, col, ...)
  self:set_selection(line, col, line2, col2)
end


return Doc
end

do
local search = {}

local default_opt = {}


local function pattern_lower(str)
  if str:sub(1, 1) == "%" then
    return str
  end
  return str:lower()
end


local function init_args(doc, line, col, text, opt)
  opt = opt or default_opt
  line, col = doc:sanitize_position(line, col)

  if opt.no_case then
    if opt.pattern then
      text = text:gsub("%%?.", pattern_lower)
    else
      text = text:lower()
    end
  end

  return doc, line, col, text, opt
end


function search.find(doc, line, col, text, opt)
  doc, line, col, text, opt = init_args(doc, line, col, text, opt)

  for line = line, #doc.lines do
    local line_text = doc.lines[line]
    if opt.no_case then
      line_text = line_text:lower()
    end
    local s, e = line_text:find(text, col, not opt.pattern)
    if s then
      return line, s, line, e + 1
    end
    col = 1
  end

  if opt.wrap then
    opt = { no_case = opt.no_case, pattern = opt.pattern }
    return search.find(doc, 1, 1, text, opt)
  end
end


return search
end

do
local common = require "core.common"
local config = require "core.config"

-- functions for translating a Doc position to another position these functions
-- can be passed to Doc:move_to|select_to|delete_to()

local translate = {}


local function is_non_word(char)
  return config.non_word_chars:find(char, nil, true)
end


function translate.previous_char(doc, line, col)
  repeat
    line, col = doc:position_offset(line, col, -1)
  until not common.is_utf8_cont(doc:get_char(line, col))
  return line, col
end


function translate.next_char(doc, line, col)
  repeat
    line, col = doc:position_offset(line, col, 1)
  until not common.is_utf8_cont(doc:get_char(line, col))
  return line, col
end


function translate.previous_word_start(doc, line, col)
  local prev
  while line > 1 or col > 1 do
    local l, c = doc:position_offset(line, col, -1)
    local char = doc:get_char(l, c)
    if prev and prev ~= char or not is_non_word(char) then
      break
    end
    prev, line, col = char, l, c
  end
  return translate.start_of_word(doc, line, col)
end


function translate.next_word_end(doc, line, col)
  local prev
  local end_line, end_col = translate.end_of_doc(doc, line, col)
  while line < end_line or col < end_col do
    local char = doc:get_char(line, col)
    if prev and prev ~= char or not is_non_word(char) then
      break
    end
    line, col = doc:position_offset(line, col, 1)
    prev = char
  end
  return translate.end_of_word(doc, line, col)
end


function translate.start_of_word(doc, line, col)
  while true do
    local line2, col2 = doc:position_offset(line, col, -1)
    local char = doc:get_char(line2, col2)
    if is_non_word(char)
    or line == line2 and col == col2 then
      break
    end
    line, col = line2, col2
  end
  return line, col
end


function translate.end_of_word(doc, line, col)
  while true do
    local line2, col2 = doc:position_offset(line, col, 1)
    local char = doc:get_char(line, col)
    if is_non_word(char)
    or line == line2 and col == col2 then
      break
    end
    line, col = line2, col2
  end
  return line, col
end


function translate.previous_block_start(doc, line, col)
  while true do
    line = line - 1
    if line <= 1 then
      return 1, 1
    end
    if doc.lines[line-1]:find("^%s*$")
    and not doc.lines[line]:find("^%s*$") then
      return line, (doc.lines[line]:find("%S"))
    end
  end
end


function translate.next_block_end(doc, line, col)
  while true do
    if line >= #doc.lines then
      return #doc.lines, 1
    end
    if doc.lines[line+1]:find("^%s*$")
    and not doc.lines[line]:find("^%s*$") then
      return line+1, #doc.lines[line+1]
    end
    line = line + 1
  end
end


function translate.start_of_line(doc, line, col)
  return line, 1
end


function translate.end_of_line(doc, line, col)
  return line, math.huge
end


function translate.start_of_doc(doc, line, col)
  return 1, 1
end


function translate.end_of_doc(doc, line, col)
  return #doc.lines, #doc.lines[#doc.lines]
end


return translate
end

