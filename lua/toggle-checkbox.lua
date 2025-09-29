local checked_character = "x"

local checked_checkbox = "%[" .. checked_character .. "%]"
local unchecked_checkbox = "%[ %]"

local line_contains_unchecked = function(line)
	return line:find(unchecked_checkbox)
end

local line_contains_checked = function(line)
	return line:find(checked_checkbox)
end

local line_with_checkbox = function(line)
	-- return not line_contains_a_checked_checkbox(line) and not line_contains_an_unchecked_checkbox(line)
	return line:find("^%s*- " .. checked_checkbox)
		or line:find("^%s*- " .. unchecked_checkbox)
		or line:find("^%s*%d%. " .. checked_checkbox)
		or line:find("^%s*%d%. " .. unchecked_checkbox)
end

local checkbox = {
	check = function(line)
		return line:gsub(unchecked_checkbox, checked_checkbox, 1)
	end,

	uncheck = function(line)
		return line:gsub(checked_checkbox, unchecked_checkbox, 1)
	end,

	make_checkbox = function(line)
		if not line:match("^%s*-%s.*$") and not line:match("^%s*%d%s.*$") then
			-- "xxx" -> "- [ ] xxx"
			return line:gsub("(%S+)", "- [ ] %1", 1)
		else
			-- "- xxx" -> "- [ ] xxx", "3. xxx" -> "3. [ ] xxx"
			return line:gsub("(%s*- )(.*)", "%1[ ] %2", 1):gsub("(%s*%d%. )(.*)", "%1[ ] %2", 1)
		end
	end,
}

local M = {}

M.toggle = function()
	local bufnr = vim.api.nvim_buf_get_number(0)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local start_line = cursor[1] - 1
	local current_line = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 1, false)[1] or ""

	-- If the line contains a checked checkbox then uncheck it.
	-- Otherwise, if it contains an unchecked checkbox, check it.
	local new_line = ""

	if not line_with_checkbox(current_line) then
		new_line = checkbox.make_checkbox(current_line)
	elseif line_contains_unchecked(current_line) then
		new_line = checkbox.check(current_line)
	elseif line_contains_checked(current_line) then
		new_line = checkbox.uncheck(current_line)
	end

	vim.api.nvim_buf_set_lines(bufnr, start_line, start_line + 1, false, { new_line })
	vim.api.nvim_win_set_cursor(0, cursor)
end

M.toggleN = function(nlines)
	nlines = nlines or 1
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local start_line = cursor[1] - 1
  local end_line = start_line + nlines

  -- Get up to 10 lines from the cursor downwards
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)

  local new_lines = {}
  for _, line in ipairs(lines) do
    local new_line = ""

    if not line_with_checkbox(line) then
      new_line = checkbox.make_checkbox(line)
    elseif line_contains_unchecked(line) then
      new_line = checkbox.check(line)
    elseif line_contains_checked(line) then
      new_line = checkbox.uncheck(line)
    else
      new_line = line -- fallback: unchanged
    end

    table.insert(new_lines, new_line)
  end

  -- Replace the lines in the buffer
  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, new_lines)

  -- Restore cursor
  vim.api.nvim_win_set_cursor(0, cursor)
end

vim.api.nvim_create_user_command("ToggleCheckbox", M.toggle, {})
vim.api.nvim_create_user_command("ToggleNCheckboxes", function(opts)
  local n = tonumber(opts.args) or 1  -- default to 1 if no number provided
  M.toggleN(n)
end, { nargs = "?" })  -- "?" = optional argument

return M

