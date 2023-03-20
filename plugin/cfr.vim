let s:jar = expand('<sfile>:h:h') .. '/cfr-latest.jar'

function! s:download() abort
  let json = json_decode(system('curl -sL https://api.github.com/repos/leibnitz27/cfr/releases/latest'))
  let assets = json['assets']
  for asset in assets
    let name_match = matchstr(asset['name'], 'cfr-[0-9\.]*\.jar')
    if !empty(name_match)
      let url = asset['browser_download_url']
      break
    endif
  endfor
  echo url
  echohl WarningMsg | echom 'Downloading cfr.jar from ' .. url | echohl None
  call system(printf('curl -sL %s -o %s', url, s:jar))
endfunction

function! s:decompile(class) abort
  if !filereadable(s:jar)
    call s:download()
  endif
  if stridx(a:class, "zipfile") != -1 && stridx(a:class, ".jar") != -1
      let clean_path = substitute(a:class, "zipfile:///", "/", "")
      let clean_path = substitute(clean_path, ".class", "", "")
      let split = split(clean_path, "::")
      let jar_file = split[0]
      let class_file = substitute(split[1], "/", ".", "g")
      let command = printf('java -jar %s --extraclasspath %s %s', s:jar, jar_file, class_file)
  else 
      let command = printf('java -jar %s %s', s:jar, a:class)
  endif

  setlocal bufhidden=hide noswapfile filetype=java modifiable
  " let command = printf('java -jar %s %s', s:jar, a:class)
  let lines = systemlist(command)
  if v:shell_error
    echoerr printf('Failed to run %s (%d)', command, v:shell_error)
    return
  endif

  normal! gg"_dG
  call setline(1, lines)
  setlocal nomodifiable
endfunction

function! s:nope()
  echohl WarningMsg | echom 'Nope.' | echohl None
endfunction

augroup vim-cfr
  autocmd!
  autocmd BufReadCmd *.class call <sid>decompile(expand('<afile>'))
  autocmd BufWriteCmd *.class call <sid>nope()
augroup END
