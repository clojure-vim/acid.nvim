
def build_window(nvim, **kwargs):
    cmds = ["topleft vertical split", "enew"]

    if 'nolist' in kwargs:
        cmds.append("setlocal nolist")

    if 'ansiesc' in kwargs and nvim.funcs.exists(':AnsiEsc'):
        cmds.append('AnsiEsc')

    if 'close' in kwargs:
        cmds.append('nmap <buffer> q :bd! %<CR>')

    try:
        nvim.command('|'.join(cmds))
    except:
        return None
    else:
        return nvim.funcs.bufnr('$')
