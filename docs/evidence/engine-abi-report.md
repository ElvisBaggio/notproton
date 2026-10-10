# ABI compare: PASS

- A: `scratch/abi/upstream-11.0-llvmmingw20260826`
- B: `scratch/abi/sikarugir`

- A `lib/wine/x86_64-unix/ntdll.so` sha256 `9895b498bd43401f8455d71a61b5f6178c6b7ced61e8b5b367d108353b309092`
- A `lib/wine/x86_64-windows/ntdll.dll` sha256 `ed357b207673b5229d81f2a623f929a4d2ce91e966f6016520f5126cf0fc24b9`
- A `lib/wine/i386-windows/ntdll.dll` sha256 `a3823f22e21a1577cae87498c79a328ba6d237b82dc55744d41d13458d2e912b`
- B `lib/wine/x86_64-unix/ntdll.so` sha256 `c9948aab11b674b182c8dd41e212cb0be10568adeb47a28721151561456f5b6c`
- B `lib/wine/x86_64-windows/ntdll.dll` sha256 `da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676`
- B `lib/wine/i386-windows/ntdll.dll` sha256 `e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589`

## Contagens

```
{
 "x86_64": {
  "exportsA": 1461,
  "exportsB": 1462,
  "syscallsA": 516,
  "syscallsB": 516
 },
 "i386": {
  "exportsA": 1483,
  "exportsB": 1484,
  "syscallsA": 528,
  "syscallsB": 528
 },
 "unix": {
  "exportsA": 287,
  "exportsB": 287,
  "tablesA": [
   {
    "n": 8,
    "shared": 7,
    "entrySizes": [
     [
      16,
      16,
      32,
      304,
      192,
      96,
      304,
      160
     ],
     [
      208,
      7504,
      32,
      80,
      192,
      96,
      32,
      160
     ]
    ]
   }
  ],
  "tablesB": [
   {
    "n": 9,
    "shared": 7,
    "entrySizes": [
     [
      16,
      16,
      32,
      384,
      192,
      96,
      320,
      144,
      16
     ],
     [
      224,
      7712,
      32,
      80,
      192,
      96,
      32,
      144,
      112
     ]
    ]
   }
  ]
 }
}
```

## Divergencias (a)-(d)

Total 11 (a=3 b=0 c=4 d=4); falhando 0.

- [irrelevante] `a:pe-export:x86_64:+__wine_unix_call`: only in B — Export adicional so na Sikarugir. Nenhum export upstream falta e nenhum ordinal/forwarder comum muda (sem divergencias a:pe-export-attr), entao todo import por nome de lsteamclient.dll/steam.exe compilados contra 11.0 resolve. Os componentes usam __wine_unix_call_dispatcher/__wine_unixlib_handle (presentes e iguais), nao __wine_unix_call.
- [irrelevante] `d:func:x86_64:build_module`: size 2001 vs 2495, insns 521 vs 626, first diff #9: ['subq $0x98, %rsp'] vs ['subq $0xa8, %rsp'] — Personalizacao Sikarugir confirmada: build_module inclui apply_binary_patches (strings 'Found matching %s, applying patch', 'CEF cmd_line_args_disabled ...' referenciadas so por build_module) e perform_relocations inlinado. Todos os deslocamentos de campos upstream aparecem na Sikarugir (nenhum exclusivo de A). Irrelevante para o que T03 consome do upstream (headers, exports, layout); NAO autoriza reutilizar offsets/bytes do upstream: T04 deve resolver o sitio no binario Sikarugir. resolve.py (leitura) falha em x86_64 tanto no upstream 11.0 quanto na Sikarugir ('load_path slot rewritten'), logo a adaptacao do resolvedor e trabalho de T04 independente desta divergencia.
- [irrelevante] `d:func:x86_64:alloc_module`: size 1474 vs 1458, insns 368 vs 367, first diff #17: ['movq %rax, -0x10(%rbp)'] vs ['movq %rax, -0x18(%rbp)'] — Diferenca apenas de alocacao de slots de pilha/alinhamento; o conjunto de deslocamentos de campos (bases nao-pilha) e de imediatos e identico (28 e 27 comuns, nenhum exclusivo), incluindo as escritas em 0x30 (DllBase) e 0x68 (Flags) de WINE_MODREF que detour.c usa. Pins de T04 sao derivados do binario Sikarugir.
- [irrelevante] `c:func:x86_64:wine_server_call`: size 22 vs 25, insns 4 vs 5, first diff #2: ['movl $0x3, %edx'] vs ['movq REL(%rip), %rax'] — Diferenca de codegen: Sikarugir carrega __wine_unix_call_dispatcher em rax e faz jmp *%rax; upstream faz jmp *mem. Mesmo codigo de unix call ($0x3), mesmos operandos de dados. Wrapper interno a ntdll Sikarugir, nao reimplementado pela ponte.
- [irrelevante] `a:pe-export:i386:+__wine_unix_call`: only in B — Mesmo caso do x86_64: superconjunto aditivo, ordinais comuns iguais.
- [irrelevante] `d:func:i386:build_module`: size 1648 vs 2145, insns 489 vs 629, first diff #6: ['subl $0x34, %esp'] vs ['subl $0x38, %esp'] — Mesma personalizacao (apply_binary_patches) que no x86_64. resolve.py (leitura) localiza o mesmo padrao de hook em upstream e Sikarugir: insn 'mov eax,[ebp+0x14]; test al,1', stolen 8b4514a801, wm edi; muda so o slot load_path (ebp-0x3c upstream, ebp-0x40 Sikarugir), que T04 deriva do binario real.
- [irrelevante] `d:func:i386:alloc_module`: size 1093 vs 1093, insns 339 vs 340, first diff #279: ['movl -0x50(%edi), %edx'] vs ['nopl (%eax)'] — Mesmo tamanho (1093 bytes); unica diferenca e preenchimento/alinhamento. Deslocamentos de campos e imediatos identicos, incluindo os usados por detour32.c (DllBase 0x18, Flags 0x34 em WINE_MODREF i386).
- [irrelevante] `c:func:i386:wine_server_fd_to_handle`: size 45 vs 63, insns 15 vs 23, first diff #3: ['subl $0x10, %esp'] vs ['pushl %esi'] — Codegen: upstream copia os 16 bytes de argumentos com movups (SSE), Sikarugir com quatro movl; mesmo codigo de unix call e mesma sequencia de chamada. Interno a ntdll Sikarugir.
- [irrelevante] `c:func:i386:wine_server_handle_to_fd`: size 45 vs 63, insns 15 vs 23, first diff #3: ['subl $0x10, %esp'] vs ['pushl %esi'] — Mesmo padrao de codegen de wine_server_fd_to_handle; imediatos iguais.
- [irrelevante] `a:unix-linkage:id`: @rpath/ntdll.so != ntdll.so — Muda so o install name proprio da ntdll.so (upstream @rpath/ntdll.so, Sikarugir ntdll.so). Os dependentes nao usam esse id: win32u.so da propria Sikarugir referencia @rpath/ntdll.so com LC_RPATH @loader_path/ (otool -L/-l, leitura do wrapper), igual ao que lsteamclient.so tera ao linkar contra a arvore upstream. Exports Unix (nm -gU) identicos e LC_RPATH @loader_path/ igual. Condicao para T03: instalar lsteamclient.so no mesmo diretorio x86_64-unix da copia isolada da engine (ou rpath equivalente) e conferir com otool.
- [irrelevante] `c:unix-table:count`: 8 != 9 — Tabela interna de unix calls da propria ntdll: Sikarugir tem 9 entradas, upstream 8; o indice compartilhado (system_time_precise) e 7 nos dois, logo a 9a entrada foi acrescentada no fim sem deslocar 0-7. Tamanhos por indice 0-7 coerentes (16,16,32,~300-384,192,96,~300,~150) e os imediatos dos wrappers PE (wine_server_call=3, fd_to_handle=4, handle_to_fd=5, __wine_dbg_write=2) coincidem. Contrato e interno ao par ntdll.dll/ntdll.so Sikarugir, que nao e substituido. Os nomes de lookup da unixlib dos modulos (__wine_unix_call_funcs, __wine_unix_call_wow64_funcs) sao iguais.

## (e) Strings (informativo, nao bloqueia)

### x86_64-unix: 72 so em A, 182 so em B
- onlyA: `!fffff.`, `"fffff.`, `%fffff.`, `+fffff.`, `,fffff.`, `/usr/local/bin`, `/usr/local/lib/wine`, `/usr/local/share/wine`, `0123456789abcdef0123456789abcdef `, `0123456789abcdefwine-11.0`, `0fffff.`, `1fffff.`, `3fffff.`, `<O=t&fffff.`, `@rpath/ntdll.so`, `ARAUAVL`, `ARAUAVM`, `ARAVAW`, `AVATSASM`, `AWAVATSLc=:`, `Mffff.`, `Pffff.`, `Rffff.`, `Setting debug registers is not supported under Rosetta`, `Wffff.`, `Zfffff.`, `^fffff.`, `__thread_set_tsd_base`, `_pipe2`, `anon mmap error %s, size %p, unix_prot %#x`, `couldn't map free area in range %p-%p, size %p`, `fffff.`, `ffffff.`, `find_reserved_free_area`, `gfffff.`, `got mem in reserved area %p-%p`, `got mem with map_free_area %p-%p`, `map_free_area`, `nt_to_unix_file_name`, `range != free_ranges_end && range->end >= start`, `t fffff.`, `t ffffff.`, `t'fffff.`, `tEfff.`, `tJffff.`, `t_ffff.`, `tafffff.`, `vice placeholderWine device plac~`, `{ ffffff.`, `~"=t$ffffff.`
- onlyB: ` (native)`, `#class="`, `(char *)prev->base + prev->size == native_mapped_start`, `//vice placeholderWine device plac~`, `/share/wine`, `0123456789abcdef.......abtnvfr.............e....\`, `0123456789abcdef0123456789abcdef@`, `0123456789abcdefsavereg.tmp`, `0123456789abcdefwine-11.0 (Sikarugir)`, `;; All keys relative to `, `ANG_INTLH`, `ARAUAWL`, `ARAUAWM`, `AVATSARI`, `AWAUAV`, `AWAVATSLc=`, `Allocation failed, clearing native views.`, `Battle.net.exe`, `BlizzardBrowser.exe`, `BlizzardError.exe`, `Built without seccomp.`, `CX_APPLEGPTK_LIBD3DSHARED_PATH`, `Cannot stat %s`, `Could not create view for natively mapped area, status %#x.`, `Could not map in reserved area, alloc_start %p, size %p.`, `EACefSubProcess.exe`, `EADesktop.exe`, `EOSOverlayRenderer-Win32-Shipping.exe`, `EOSOverlayRenderer-Win64-Shipping.exe`, `EpicGamesLauncher.exe`, `EpicWebHelper.exe`, `Excluding %p - %p from free list.`, `Failed bootstrap_look_up for %s`, `Failed task_get_special_port`, `Failed to allocate reply port: %s`, `Failed to grow shm_addrs array to size %d.`, `Failed to insert right into reply port: %s`, `Failed to map page %d (offset %#lx).`, `Failed to map shm entry: %u: %d (%s)`, `Failed to map tid shared memory`, `Failed to send message to server to close msync object %d: %#x`, `Failed to send server register wait: %#x`, `Failed to send server remove wait: %#x`, `Failed to send/receive shm map request: %#x`, `GOG Galaxy Notifications Renderer.exe`, `GalaxyClient Helper.exe`, `GalaxyClient.exe`, `HACK: exec fault on executable page, addr %p`, `HACK: write fault on a w|x page, addr %p`, `Invalid type %#x for obj %d.`, `Loaded libd3dshared.dylib, does%s support non-native code regions`, `Loading libd3dshared.dylib failed: %s`, `Mapping page %d at %p.`, `Marking non_native_code_region: %p-%p`, `No memory.`, `ORTDEFAUH`, `ROSETTA_X87_PATH`, `Restricting number of processors to %ld.`, `Rockstar Games\Launcher\Launcher.exe`, `Rockstar Games\Social Club\SocialClubHelper.exe`, `SectionLH`, `SectionSH`, `Server is running with WINEMSYNC but this process is not, please enable WINEMSYN`, `Setting debug registers is not supported under Rosetta, faking success`, `SikarugirAppWine11`, `UbisoftConnect.exe`, `UpcElevationService.exe`, `UplayWebCore.exe`, `Using mach_msg instead of mach_msg2`, `WINE REGISTRY Version 2`, `WINEDLLPATH_CNCD`, `WINEDLLPATH_D3DMETAL`, `WINEDLLPATH_D9VK`, `WINEDLLPATH_DXMT`, `WINEDLLPATH_DXVK`, `WINEMSYNC`, `WINENCPU`, `\Sessions\%u\BaseNamedObjects\__wine_regkey_flush`, `\SystemRM`, `__DefaultRuneLocale`

### x86_64: 127 so em A, 89 so em B
- onlyA: ` ffffff.`, `!fffff.`, `#ffffff.`, `%ffffff.`, `(ffffff.`, `)ffffff.`, `,fffff.`, `-fffff.`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `/fffff.`, `0123456789abcdef8`, `0123456789abcdefHB`, `0fffff.`, `2fffff.`, `4ffffff.`, `5fffff.`, `8fffff.`, `;ffffff.`, `@fffff.`, `AVVWUSM`, `Fffffff.`, `Offffff.`, `UUUUUUUUUUUUUUUU3333333333333333`, `VWSff.`, `[ffffff.`, `\$0fffff.`, `fffff.`, `ffffff.`, `iiiiiiiiiiiiiiiiIwiiiiiiiiIsiiiiiiiiIiiiiiwwiIiiiiissiIiiwwiiiIiiiiiwIiiwwwwIiii`, `lfffff.`, `t$,ffffff.`, `t$hffffff.`, `t%fffff.`, `t(fffff.`, `t)ffffff.`, `t:ffffff.`, `tAfffff.`, `tAffffff.`, `tEffffff.`, `ufffff.`, `vhffff.`, `|$Lffffff.`, `|$pffffff.`, `|]ffffff.`
- onlyB: `%s doesn't match patch '%s'`, `%s too small to match patch '%s'`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/exception.c: vectored_hand`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/heap.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/heap.c: heap.cs`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/heap.c: main process heap `, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/loader.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/loader.c: dlldir_section`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/loader.c: loader_section`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/loader.c: peb_lock`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/sync.c: RTL_RWLOCK.rtlCS`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/thread.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/thread.c: fls_section`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: ioqueue.cs`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: threadpool.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: threadpool_c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: threadpool_g`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: timerqueue.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: waitqueue.cs`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/unwind.c: dynamic_unwind_s`, `0123456789abcdef0`, `CEF cmd_line_args_disabled 90.6.7`, `Darwin`, `Found matching %s, applying patch '%s'`, `__wine_unix_call`, `apply_binary_patches`, `getting HideWineExports from %s`, `getting default HideWineExports`, `hidden_exports_init`, `iiiiiiiiiiiiiiiiIsiiiiiiiiIwiiiiiiiiIiiiiiwwiIiiiiissiIiiwwiiiIiiiiwiIiwiiiiIiiw`, `wine-sikarugir %s is a testing version containing experimental patches.`, `winediag`

### i386: 407 so em A, 394 so em B
- onlyA: ` fffff.`, `%fffff.`, `*ffffff.`, `,fffff.`, `,ffffff.`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `~/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0/dll`, `2fffff.`, `4ffffff.`, `6WPQhm`, `;fffff.`, `?ffffff.`, `Bffff.`, `Bffffff.`, `Effff.`, `Efffff.`, `Hfffff.`, `L$HPhDo`, `Offffff.`, `Qfffff.`, `UUUUUUUUUUUUUUUU3333333333333333`, `Uffffff.`, `VRQPhh`, `WVPRQh(S`, `WVPRQhTS`, `Xffffff.`, `fffff.`, `ffffff.`, `iiiiiiiiiiiiiiiiIwiiiiiiiiIsiiiiiiiiIiiiiiwwiIiiiiissiIjijiiiiiIiiwwiiiIiiwwwwIi`, `t PWSVh<`, `t SWQVhj`, `t$ffffff.`, `t(VRSQPWhf`, `t.ffffff.`, `tCffffff.`, `tHPVQhU`, `tHfff.`, `tpfff.`, `vffff.`, `{fffff.`, `|fffff.`
- onlyB: `%s doesn't match patch '%s'`, `%s too small to match patch '%s'`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/exception.c: vectored_hand`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/heap.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/heap.c: heap.cs`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/heap.c: main process heap `, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/loader.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/loader.c: dlldir_section`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/loader.c: loader_section`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/loader.c: peb_lock`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/relay.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/sync.c: RTL_RWLOCK.rtlCS`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/thread.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/thread.c: fls_section`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: ioqueue.cs`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: threadpool.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: threadpool_c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: threadpool_g`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: timerqueue.c`, `/Users/gcenx/Documents/GitHub/wine-private/dlls/ntdll/threadpool.c: waitqueue.cs`, `0123456789abcdef(%p,%lu,0x%08lx) semi-stub`, `CEF cmd_line_args_disabled x86 111.2.7`, `CEF cmd_line_args_disabled x86 135.0.20`, `Found matching %s, applying patch '%s'`, `L$HPhXo`, `RQWVh}`, `T$lRQPW`, `WVPRQh8S`, `WVPRQhdS`, `__wine_unix_call`, `apply_binary_patches`, `getting HideWineExports from %s`, `getting default HideWineExports`, `hidden_exports_init`, `iiiiiiiiiiiiiiiiIwiiiiiiiiIsiiiiiiiiIiiiiiwwiIiiiiissiIjijiiiiiIiiwwiiiIiiwiiiIi`, `t PWSVh`, `t SWQVhz`, `t(VRSQPWh`, `tHPVQh`, `wine-sikarugir %s is a testing version containing experimental patches.`, `winediag`, `{Wine builtin DLL`

