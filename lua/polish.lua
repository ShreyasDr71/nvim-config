vim.keymap.set('n', '<F5>', function()
  vim.cmd('write')
  local ft = vim.bo.filetype
  local file = vim.fn.expand('%')
  local root = vim.fn.expand('%:r')
  local cmd = ""

  if ft == 'cpp' or ft == 'c' then
    cmd = string.format('g++ -g "%s" -o "%s.exe" && "%s.exe"', file, root, root)
  elseif ft == 'java' then
    local class_name = vim.fn.expand('%:t:r')
    cmd = string.format('javac "%s" && java "%s"', file, class_name)
  elseif ft == 'python' then
    cmd = string.format('python "%s"', file)
  else
    print("No build rule for filetype: " .. ft)
    return
  end

  vim.cmd('10new')
  vim.fn.termopen(cmd)
  vim.cmd('startinsert')
end, { desc = "Smart Compile and Run" })