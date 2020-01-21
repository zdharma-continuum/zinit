```zsh
zinit ice atinit'zmodload zsh/zprof' \
    atload'zprof | head -n 20; zmodload -u zsh/zprof'
zinit light zdharma/fast-syntax-highlighting
```

 - `atinit''` loads `zsh/zprof` module (shipped with Zsh) before loading the
   plugin – this starts the profiling,
 - `atload''` works after loading the plugin – shows profiling results (`zprof |
   head`), unloads `zsh/zprof` - this stops the profiling; in the effect, only a
   single plugin (in this case `zdharma/fast-syntax-highlighting`) will be
   profiled while the rest of the e.g. zshrc processing will go on completely
   normally,
 - the `light` loads without reporting enabled, so less Zinit code is being
   run – no Zinit code responsible for the tracking (i.e. the automatic data
   gathering, during loading of a plugin, for the reports and the possibility to
   unload the plugin) will be activated and the functions will not appear in the
   `zprof` report.
 - example `zprof` report: 

```
num calls    time                self                 name
---------------------------------------------------------------------------
 1)  1 57,76 57,76 57,91%  57,76 57,76 57,91% _zsh_highlight_bind_widgets
 2)  1 25,81 25,81 25,88%  25,81 25,81 25,88% compinit
 3)  4 10,71  2,68 10,74%   8,71  2,18  8,73% --zplg-shadow-autoload
 4) 43  2,06  0,05  2,07%   2,06  0,05  2,07% -zplg-add-report
 5)  8  1,98  0,25  1,98%   1,98  0,25  1,98% compdef
 6)  1  2,85  2,85  2,85%   0,87  0,87  0,87% -zplg-compdef-replay
 7)  1  0,68  0,68  0,68%   0,68  0,68  0,68% -zplg-shadow-off
 8)  1  0,79  0,79  0,79%   0,49  0,49  0,49% add-zsh-hook
 9)  1  0,47  0,47  0,47%   0,47  0,47  0,47% -zplg-shadow-on
10)  3  0,34  0,11  0,35%   0,34  0,11  0,35% (anon)
11)  4 10,91  2,73 10,94%   0,20  0,05  0,20% autoload
12)  1  0,19  0,19  0,19%   0,19  0,19  0,19% -fast-highlight-fill-option-variables
13)  1 25,98 25,98 26,05%   0,17  0,17  0,17% zpcompinit
14)  1  2,88  2,88  2,89%   0,03  0,03  0,03% zpcdreplay
15)  1  0,00  0,00  0,00%   0,00  0,00  0,00% -zplg-load-plugin
-----------------------------------------------------------------------------------
```

- the first column is the time is in milliseconds; it denotes the amount of time
  spent in a function in total
    - so for example, `--zplg-shadow-autoload`
      consumed 10.71 ms of the execution time,
- the fourth column is also a time in milliseconds, but it denotes the amount of
  time spent on executing only of function's **own code**, i.e. it doesn't count
  the time spent in **descendant functions** that are called from the function;
    - so for example, `--zplg-shadow-autoload` spent 8.71 ms on executing only
      its own code.
- the table is sorted on the **self-time** column.

[]( vim:set ft=markdown tw=80: )
