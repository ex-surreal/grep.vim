if exists("g:grep_vim_loaded")
  finish
endif

let g:grep_vim_loaded = 1

function! s:unletJob(ch, data, event)
  unlet g:uc_grep_running_job
endfunction

function! s:putInQuickFix(ch, expr)
  caddexpr a:expr
endfunction

function! s:logError(ch, msg)
  echoerr a:msg
endfunction

function! s:putInQuickFixNvim(ch, expr, no)
  caddexpr a:expr
endfunction

function! s:jobStart(command)
  if has('nvim')
    return jobstart(a:command, {
          \ 'on_stdout': function('s:putInQuickFixNvim'),
          \ 'on_exit': function('s:unletJob')
          \ })
  else
    return job_start(a:command, {
          \ 'out_cb': function('s:putInQuickFix'),
          \ 'err_cb': function('s:logError')
          \ })
  endif
endfunction

function! s:jobStop(job)
  if has('nvim')
    call jobstop(a:job)
  else
    call job_stop(a:job, 'kill')
  endif
endfunction

function! Grep(args, bang)
  let l:cmd = &grepprg . ' ' . a:args
  call setqflist([])
  if exists('g:uc_grep_running_job')
    call s:jobStop(g:uc_grep_running_job)
  endif
  let g:uc_grep_running_job = s:jobStart(['sh', '-c', l:cmd], )
  let l:buf = bufwinnr(bufname('%'))
  copen
  if a:bang | execute l:buf . 'wincmd w' | endif
endfunction

function! GrepMotion(type)
  if a:type !=# 'char' | return | endif
  let tmp = @@
  silent exe "normal! `[v`]y"
  call Grep(shellescape(@@), 1)
  let @@ = tmp
endfunction

command! -bang -nargs=+ Grep call Grep(<q-args>, <bang>0)
nnoremap ga :set operatorfunc=GrepMotion<CR>g@
