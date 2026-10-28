local is_windows = vim.fn.has('win32') == 1
local python = is_windows and 'python' or 'python3'

vim.keymap.set('n', '<F5>', function()
  vim.cmd('write')
  local ft = vim.bo.filetype
  local file = vim.fn.expand('%')
  local root = vim.fn.expand('%:r')
  local cmd = ""

  if ft == 'cpp' or ft == 'c' then
    local exe = is_windows and (root .. '.exe') or ('./' .. root)
    cmd = string.format('g++ -g "%s" -o "%s" && "%s"', file, exe, exe)
  elseif ft == 'java' then
    local class_name = vim.fn.expand('%:t:r')
    cmd = string.format('javac "%s" && java "%s"', file, class_name)
  elseif ft == 'python' then
    cmd = string.format('%s "%s"', python, file)
  else
    print("No build rule for filetype: " .. ft)
    return
  end

  vim.cmd('10new')
  vim.fn.termopen(cmd)
  vim.cmd('startinsert')
end, { desc = "Smart Compile and Run" })
