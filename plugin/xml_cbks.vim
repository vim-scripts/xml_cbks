" Vim global plugin to extend the functionality of xmledit so that a different
" XmlAttribCallback_() function is called for each XML doctype (schema).
"
" See :help xml_cbks for details.
"
" Maintainer:  Brett Williams <brett_williams@agilent.com>
" Last Change: 2003 Jun 15
"
" TODO:
"   * Find a much much better way to determine the doctype than via the
"   current XmlFindDocType().  This is my first vim script (I've been using
"   vim for only about 2 weeks) and this function is certainly less than
"   ideal, both in concept and implementation.  Suggestions for improvement
"   are welcome.  At any rate, if you define this same function and have it
"   set b:xml_doctype the rest of the plugin should work fine.
"
"   * Clean up pollution of global namespace.
"       - XmlFindDocType()
"       - XmlAttribCallback_*()
"     I'm not quite sure how to get around these.  The first is global so that
"     it is easily overridden (see above).  I considered not including any way
"     to have the doctype set automatically but this works for me and might be
"     useful to others, bad as it is.
"
"     The second are global because they will be defined in an arbitrary
"     script.  Apparently buffer local functions are not allowed.
"
"   * Convert this big comment block into a vim help file.
"
"   * Add an example file that would be placed in $VIMXMLEDITCALLBACKS

if exists("loaded_xml_cbks")
  finish
endif
let loaded_xml_cbks = 1

" set up default for where the {b:xml_doctype}.vim files will be
if !exists('$VIMXMLEDITCALLBACKS')
  let $VIMXMLEDITCALLBACKS=$HOME.'/.vim/xml_cbks'
endif

" AUTOCMDS:

" Set a hook so that whenever a filetype is set to xml the relevant doctype
" script will be sourced.
autocmd FileType xml call s:XmlLoadDoctypeScript()


" FUNCTIONS:

"1.  Get the doctype with XmlFindDocType 
"2.  Look for the relevant function script
"3.  If found, load the script
function s:XmlLoadDoctypeScript()
  if !exists("b:sourced_doctype_script")
    call s:XmlFindDocType()
    " set this even if the file didn't exist so we don't try again
    let b:sourced_doctype_script = 1
    let s:xml_func_file=$VIMXMLEDITCALLBACKS.'/'.b:xml_doctype.'.vim'
    if filereadable(s:xml_func_file)
      execute "source ".s:xml_func_file
    endif
    unlet s:xml_func_file
  endif
endfunction

" This function is quite lame.  It can be overridden--the only intent is to
" set the variable b:xml_doctype.  If it is already set, then the function is
" harmless and just returns.  It works by searching through the
" first 10 lines of the program for the part of a DTD DOCTYPE declaration,
" assuming that the tail of the URL is /somename.dtd.  It sets b:xml_doctype
" to somename.  It is not very robust.  Just set b:xml_doctype if it doesn't
" work for you (this can be done in an xml ftplugin).
function s:XmlFindDocType()
  if exists("b:xml_doctype")
    return
  endif
  let s:i = 0
  while s:i < 10
    let s:i = s:i + 1
    let s:line = getline(s:i)
    let s:pat = "/[^/]*\\.dtd"
    let s:match_pos = match(s:line, s:pat)
    if s:match_pos > -1
      let s:match_end = matchend(s:line, s:pat)
      "skip leading / and trailing .dtd
      let b:xml_doctype = strpart(s:line, s:match_pos+1, s:match_end-5-s:match_pos)
      unlet s:match_end
      echom "Setting xml_doctype to " . b:xml_doctype
      break
    endif
    if s:i == 10
      let b:xml_doctype = "unknown"
    endif
    unlet s:line
    unlet s:pat
    unlet s:match_pos
  endwhile 
  unlet s:i
endfunction

" This function is called by the xmledit package whenever a tag is inserted.
" If this function is already defined then this plugin will not work.
if exists("*XmlAttribCallback")
  echohl WarningMsg | echo "XmlAttribCallback already set" | echohl None
else
  function XmlAttribCallback(xml_tag)
    if exists("b:xml_doctype")
      if exists("*XmlAttribCallback_{b:xml_doctype}")
        return XmlAttribCallback_{b:xml_doctype}(a:xml_tag) 
      endif
    endif
    return ""
  endfunction
endif


