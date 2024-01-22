## [3.13.1](https://github.com/zdharma-continuum/zinit/compare/v3.13.0...v3.13.1) (2024-01-22)


### Bug Fixes

*  `plugins` command correctly handles keyword argument ([#626](https://github.com/zdharma-continuum/zinit/issues/626)) ([f26d387](https://github.com/zdharma-continuum/zinit/commit/f26d387e51c9103f2ba7142a8c1a25ba1d62e065))

# [3.13.0](https://github.com/zdharma-continuum/zinit/compare/v3.12.1...v3.13.0) (2024-01-18)


### Bug Fixes

* **ci:** remove duplicate gh-r  zunit job ([#623](https://github.com/zdharma-continuum/zinit/issues/623)) ([70cefc0](https://github.com/zdharma-continuum/zinit/commit/70cefc086a8b2277476e7f4fa3e00e0f7d4fd4cf))
* debug logging logic and format ([#592](https://github.com/zdharma-continuum/zinit/issues/592)) ([3c7e5be](https://github.com/zdharma-continuum/zinit/commit/3c7e5be07d79b8f1a7fbd5dfd150a09a6309e461))
* handle zinit --help ([#597](https://github.com/zdharma-continuum/zinit/issues/597)) ([8cf9104](https://github.com/zdharma-continuum/zinit/commit/8cf9104ac08da3f7f108a32e0a3b117e22681d46))
* link ice check in .zinit-download-snippet function ([#608](https://github.com/zdharma-continuum/zinit/issues/608)) ([358ef03](https://github.com/zdharma-continuum/zinit/commit/358ef03785a18e694e94fd4560e0582c4024bcc3))
* pin dua gh-r test to v2.20.3 ([#605](https://github.com/zdharma-continuum/zinit/issues/605)) ([0ba778a](https://github.com/zdharma-continuum/zinit/commit/0ba778ac734e33c960fe08bbd56a351b1b86dcd4))
* silence unzip command in ziextract ([#614](https://github.com/zdharma-continuum/zinit/issues/614)) ([71764bf](https://github.com/zdharma-continuum/zinit/commit/71764bf2caa553f52435ed374bb48b74b0a8ad96))
* tar permissions when `ziextract` ran as root user ([#557](https://github.com/zdharma-continuum/zinit/issues/557)) ([e2d477c](https://github.com/zdharma-continuum/zinit/commit/e2d477cde4e87d13ebc6b99e7f95022f75ca075e))
* update labeler config to v5 ([#604](https://github.com/zdharma-continuum/zinit/issues/604)) ([794723c](https://github.com/zdharma-continuum/zinit/commit/794723cc4829e0f9293fc441100913ac7f02566a))


### Features

* configure, make, cmake, and build ices ([#613](https://github.com/zdharma-continuum/zinit/issues/613)) ([#616](https://github.com/zdharma-continuum/zinit/issues/616)) ([22e66db](https://github.com/zdharma-continuum/zinit/commit/22e66db478716005d6fec52cd412fad3fc94a9a2))
* **delete:** fix unsetting plugin state & add `--debug` / `--quiet` flags ([#622](https://github.com/zdharma-continuum/zinit/issues/622)) ([3f4b685](https://github.com/zdharma-continuum/zinit/commit/3f4b68562265e6b06f55124e34fab0fe58c53adf))
* remove zpextract and use ziextract ([#611](https://github.com/zdharma-continuum/zinit/issues/611)) ([2ccac85](https://github.com/zdharma-continuum/zinit/commit/2ccac85e376965a6e6d9fe1dc3f1470b706e9fac))

## [3.12.1](https://github.com/zdharma-continuum/zinit/compare/v3.12.0...v3.12.1) (2023-11-20)


### Bug Fixes

* container zshelldoc install ([#591](https://github.com/zdharma-continuum/zinit/issues/591)) ([8170753](https://github.com/zdharma-continuum/zinit/commit/8170753a5d21f2e54ba30901cdb0afb6399a7b51))
* from'gh-r' skips compile by default ([#590](https://github.com/zdharma-continuum/zinit/issues/590)) ([1f52eee](https://github.com/zdharma-continuum/zinit/commit/1f52eee1b1ef4a76b779d2017f2e7d2151516544))
* respect delete flags after positional arguments ([#587](https://github.com/zdharma-continuum/zinit/issues/587)) ([e18f9a7](https://github.com/zdharma-continuum/zinit/commit/e18f9a7da273fa44079b16a90e89df76664fcbee))
* set home dir to test env in gh-r tests ([#582](https://github.com/zdharma-continuum/zinit/issues/582)) ([9b33288](https://github.com/zdharma-continuum/zinit/commit/9b33288b4aa88a1d41786eacfe31eb966b6c0455))
* use $MACHTYPE instead of arch command ([#588](https://github.com/zdharma-continuum/zinit/issues/588)) ([bcf70e8](https://github.com/zdharma-continuum/zinit/commit/bcf70e8268dd09737d262919dcba0ff3301a705d))

# [3.12.0](https://github.com/zdharma-continuum/zinit/compare/v3.11.0...v3.12.0) (2023-08-30)


### Bug Fixes

* build container for tagged releases ([f933dc0](https://github.com/zdharma-continuum/zinit/commit/f933dc028e9968ed434c21775c2bfc85a722ee04))
* gh-r linux regex & gh-r zunit tests ([#564](https://github.com/zdharma-continuum/zinit/issues/564)) ([207ab9f](https://github.com/zdharma-continuum/zinit/commit/207ab9f281214bc07da82e7e542126745bf878dd))
* gh-r zunit tests ([#561](https://github.com/zdharma-continuum/zinit/issues/561)) ([97b087e](https://github.com/zdharma-continuum/zinit/commit/97b087e68ae0c87cc31bcc9172cedf1cf5fcab68))
* Ignore .yaml and .py files when installing completions ([#528](https://github.com/zdharma-continuum/zinit/issues/528)) ([113cfc4](https://github.com/zdharma-continuum/zinit/commit/113cfc47fb6ec1ed753222b7ba4542ef48ca2fde))
* jq has moved from stedolan/jq to jqlang/jq ([#530](https://github.com/zdharma-continuum/zinit/issues/530)) ([de85908](https://github.com/zdharma-continuum/zinit/commit/de85908f8d0b89ff6327adfa285ca5a0c4302f2d))
* math expression in plugins command ([#559](https://github.com/zdharma-continuum/zinit/issues/559)) ([68a6b42](https://github.com/zdharma-continuum/zinit/commit/68a6b42caf224b2ca2c172d58daf9faf5c86beb9))
* pin fclones version to v0.31.0 ([497d519](https://github.com/zdharma-continuum/zinit/commit/497d519d99c3d3cdb8e71dfdf4583cadef9220a0))
* quote parens so that they aren't used as globs ([#549](https://github.com/zdharma-continuum/zinit/issues/549)) ([1375adf](https://github.com/zdharma-continuum/zinit/commit/1375adf8f8edadbdcfc18445d852c7f08e723887))
* self-update check for updates ([#562](https://github.com/zdharma-continuum/zinit/issues/562)) ([b456a2d](https://github.com/zdharma-continuum/zinit/commit/b456a2dba65673f4cf5a9a8c2bc16d7d0dcb3ace))
* update gomi repo owner ([#568](https://github.com/zdharma-continuum/zinit/issues/568)) ([19ca2dc](https://github.com/zdharma-continuum/zinit/commit/19ca2dc361f9995a3e6a8a8aed0ade435168cd3d))


### Features

* build container with zsh 5.9 ([#525](https://github.com/zdharma-continuum/zinit/issues/525)) ([238e843](https://github.com/zdharma-continuum/zinit/commit/238e843d60de27b8f3deaf2d0b5e6657b293c9eb))

# [3.11.0](https://github.com/zdharma-continuum/zinit/compare/v3.10.0...v3.11.0) (2023-05-04)


### Bug Fixes

* add `.gitignore` with '*' pattern in a plugins `._zinit/` directory ([#397](https://github.com/zdharma-continuum/zinit/issues/397)) ([fccb508](https://github.com/zdharma-continuum/zinit/commit/fccb5080ab4b1df83f01906082eea444f218776f)), closes [#395](https://github.com/zdharma-continuum/zinit/issues/395)
* broken update command ([336ca85](https://github.com/zdharma-continuum/zinit/commit/336ca85ade5d4c5c99bd903610baf9961753192b))
* cleanup style, naming, and completion ([6c82d67](https://github.com/zdharma-continuum/zinit/commit/6c82d6788dec6a60c4c217d03c45c327bc0e59a1))
* compile and completion log messages ([c4446da](https://github.com/zdharma-continuum/zinit/commit/c4446da57e5375f4a89ea94e1e8c04eacfc4e494))
* csearch ignores lua files ([4d1840b](https://github.com/zdharma-continuum/zinit/commit/4d1840b883e86cc46df2050c01bd0731e29023aa))
* makefile clean target less verbose ([3396f5e](https://github.com/zdharma-continuum/zinit/commit/3396f5e3aa1fb81d128d4f34b9ff868011d68981))
* pin git-mkver gh-r test to v.1.2.2 ([a05cc1a](https://github.com/zdharma-continuum/zinit/commit/a05cc1ab59db5b82c5a0f7ee0b6bbef84f0e8b0e))
* pin git-mkver unit test to v1.2.2 ([08f02e0](https://github.com/zdharma-continuum/zinit/commit/08f02e00d0fbc86b10d44d18f5b774c9c00806cc))
* regenerate docs ([e0177e2](https://github.com/zdharma-continuum/zinit/commit/e0177e20382d8336d55bc2637a6f2c515d25ce19))


### Features

* expand gh-r zunit tests ([c323116](https://github.com/zdharma-continuum/zinit/commit/c3231164836c8ca3ca9ebded8d95c31c0a186567))
* refactor debug commands ([930b25e](https://github.com/zdharma-continuum/zinit/commit/930b25ee3c6cc66931eda0030c422fddd69ef9c4))
* refactor ls, list, and loaded commands ([a865907](https://github.com/zdharma-continuum/zinit/commit/a86590762ac2bb5244db5d3cd7d99d32a9dc11fe))

# [3.10.0](https://github.com/zdharma-continuum/zinit/compare/v3.9.0...v3.10.0) (2023-04-02)


### Bug Fixes

* absolute path support in the symbol browser ([d29a8ba](https://github.com/zdharma-continuum/zinit/commit/d29a8ba2b757b936663c16d12e46d3638f44027a))
* assign to functions hash to make %x work ([bd65a01](https://github.com/zdharma-continuum/zinit/commit/bd65a017345ac891b6b14eb5feb4182bc9c74ace))
* broken symbolic link after `creinstall .` ([da0d6b7](https://github.com/zdharma-continuum/zinit/commit/da0d6b712c6466d11165ac9e27a6cd7de856e537))
* bump node version in release workflow ([938f483](https://github.com/zdharma-continuum/zinit/commit/938f48375b20545078b63d6c1dba0a905599afe4))
* change prefix `~zi::` to `__zi::` ([0e45493](https://github.com/zdharma-continuum/zinit/commit/0e45493e36ff350c79c164895bd4718103e2cf7a))
* container build & shell make targets ([a72fb83](https://github.com/zdharma-continuum/zinit/commit/a72fb83f0999a7fa4a26c6e1bb71d6cab3858b4f))
* container build & shell make targets ([14b2cda](https://github.com/zdharma-continuum/zinit/commit/14b2cda0397c343b1bfdc041cba7c4ab216e3803))
* container build & shell make targets ([370808d](https://github.com/zdharma-continuum/zinit/commit/370808dd5186f4b9c8a214e7ef6f4350df243b5b))
* container build & shell make targets ([47bd74f](https://github.com/zdharma-continuum/zinit/commit/47bd74f8a7c74761e9b03943d3c40fc523df585f))
* container build & shell make targets ([f8eb967](https://github.com/zdharma-continuum/zinit/commit/f8eb967b0e98f135b43cb5065aceb8a4f058aa09))
* container build & shell make targets ([3af321e](https://github.com/zdharma-continuum/zinit/commit/3af321e8e4975a07634df08acda383e4cf53e99c))
* do not run `make docs` ([3802893](https://github.com/zdharma-continuum/zinit/commit/3802893c74988fc03bad086601c905a1046a9fc1))
* failing zunit tests & bootstrap script ([d618467](https://github.com/zdharma-continuum/zinit/commit/d618467ff090a6dbfb327ca0a29141d0c9312b24))
* file modelines ([75bb735](https://github.com/zdharma-continuum/zinit/commit/75bb73547ed24ab6d25e1aed03684caebba39f5e))
* gh-r & bpick ice log format and content ([ad88a89](https://github.com/zdharma-continuum/zinit/commit/ad88a890ad25505acb764f9551ee00d5264daa9a))
* gh-r parsing logic for arm64 & logging style ([7e48651](https://github.com/zdharma-continuum/zinit/commit/7e486519d7aad48a8b6009ae5075f0efec2409f9))
* gh-r pattern for 64bit linux-gnu systems ([b5a31c0](https://github.com/zdharma-continuum/zinit/commit/b5a31c07f2bd2d823ce9e99b98228ec68db523bd))
* lsd repo owner changed to lsd-rs organization ([#489](https://github.com/zdharma-continuum/zinit/issues/489)) ([824d9d3](https://github.com/zdharma-continuum/zinit/commit/824d9d36177dac00a81333205e2b3dfbc35cb758))
* make gh-r release search case-insensitive ([3eb75b7](https://github.com/zdharma-continuum/zinit/commit/3eb75b7ee9db4dd01455811cf4ca4539dd07246b))
* make target docker cmd flags ([dd04896](https://github.com/zdharma-continuum/zinit/commit/dd048964491b9a63f4622b591b9a227d5e981408))
* pin `ggsrun` version in gh-r z-unit test ([9f67798](https://github.com/zdharma-continuum/zinit/commit/9f677989e8386469bc2d5dcb0d2cb5d62d489e34))
* the starship example does not work properly ([4933b62](https://github.com/zdharma-continuum/zinit/commit/4933b62f400a1b6b29b82a9ff233911b336a33c5))
* update pygmentize flags in glance subcommand ([#488](https://github.com/zdharma-continuum/zinit/issues/488)) ([b773763](https://github.com/zdharma-continuum/zinit/commit/b773763bdc37d414a5d954ccb00877374177f0ec))
* use correct return code in zinit-confirm ([d467738](https://github.com/zdharma-continuum/zinit/commit/d467738c1b1c834e938b4b4bb6e83cab5bfdc429))
* vim modelines & zsdoc pdf rendering ([2b460a7](https://github.com/zdharma-continuum/zinit/commit/2b460a74f236178cd8d06b55069049381d79256e))


### Features

* delete subcommand refactor ([9eee215](https://github.com/zdharma-continuum/zinit/commit/9eee215e3f8ee7d8404e4e54f8ef57a57a21fde2)), closes [#57](https://github.com/zdharma-continuum/zinit/issues/57) [#239](https://github.com/zdharma-continuum/zinit/issues/239)
* zinit completion improvements ([b8d12e5](https://github.com/zdharma-continuum/zinit/commit/b8d12e555d4cadff7769ef67c5d4c0d403f0b11e))


### Reverts

* "Merge branch 'refactor/zinit-function-names' into main" ([515688b](https://github.com/zdharma-continuum/zinit/commit/515688bc976e793422d21ba9debfdd1a982c611e))

# [3.9.0](https://github.com/zdharma-continuum/zinit/compare/v3.8.0...v3.9.0) (2022-12-17)


### Bug Fixes

* remove broken gh-r zunit test for "warp" ([#430](https://github.com/zdharma-continuum/zinit/issues/430)) ([64fa4ae](https://github.com/zdharma-continuum/zinit/commit/64fa4aef3ae517afe5444b24df9603e9d1a77a55))


### Features

* add `completions` ice ([#417](https://github.com/zdharma-continuum/zinit/issues/417)) ([59975d7](https://github.com/zdharma-continuum/zinit/commit/59975d70d7101651b0bb01f4e22c23db0dae8133))
* display version via `version` sub command ([bfb01e6](https://github.com/zdharma-continuum/zinit/commit/bfb01e65d7b9a98c643f3ee0a92f2df06372f52e))


### Performance Improvements

* reduce scheduler task check to 10 second interval ([#429](https://github.com/zdharma-continuum/zinit/issues/429)) ([1681ce4](https://github.com/zdharma-continuum/zinit/commit/1681ce40ebf98e5bf48b78ac5d6c060c1ecada99))


### Reverts

* "perf: reduce scheduler task check to 10 second interval ([#429](https://github.com/zdharma-continuum/zinit/issues/429))" ([#432](https://github.com/zdharma-continuum/zinit/issues/432)) ([cfd3261](https://github.com/zdharma-continuum/zinit/commit/cfd32618921ce0626a6deadc794da962750a845d))

# [3.8.0](https://github.com/zdharma-continuum/zinit/compare/v3.7.0...v3.8.0) (2022-11-07)


### Bug Fixes

* account for systems where musl is present ([#269](https://github.com/zdharma-continuum/zinit/issues/269)) ([8620574](https://github.com/zdharma-continuum/zinit/commit/8620574a5533695525260fd88df8d249c701217f))
* alist repository for gh-r test ([#305](https://github.com/zdharma-continuum/zinit/issues/305)) ([fb3c082](https://github.com/zdharma-continuum/zinit/commit/fb3c082551ee9f48676c3183d5a4e9e842d3d874))
* allow zinit to be run from non-interactive scripts ([#227](https://github.com/zdharma-continuum/zinit/issues/227)) ([c3d1bb5](https://github.com/zdharma-continuum/zinit/commit/c3d1bb586c77a98566c552358fd9aee084e30da8)), closes [#199](https://github.com/zdharma-continuum/zinit/issues/199)
* broken yaml syntax in issue template ([#355](https://github.com/zdharma-continuum/zinit/issues/355)) ([f729e06](https://github.com/zdharma-continuum/zinit/commit/f729e065db88a5cd0daa8a6f2bd2f8ee0439545a))
* calico gh-r zunit test ([#356](https://github.com/zdharma-continuum/zinit/issues/356)) ([56fb9e0](https://github.com/zdharma-continuum/zinit/commit/56fb9e0b1df21de809a2efc935882b49e9161618))
* change ctags symbols browser key  binding from `ctrl-k` to `alt-Q` ([#387](https://github.com/zdharma-continuum/zinit/issues/387)) ([7f6dc7d](https://github.com/zdharma-continuum/zinit/commit/7f6dc7da6c824b30c0e8e30ae0ecbda5be118e68)), closes [#386](https://github.com/zdharma-continuum/zinit/issues/386)
* Do not try to escape exclamation marks ([#399](https://github.com/zdharma-continuum/zinit/issues/399)) ([0e55b2e](https://github.com/zdharma-continuum/zinit/commit/0e55b2ea673915c462af752ee7d46fff55e6f436))
* docs workflow should fail if out-of-date ([#278](https://github.com/zdharma-continuum/zinit/issues/278)) ([07cde66](https://github.com/zdharma-continuum/zinit/commit/07cde660081c91382ce73b60485839710154c7c6))
* Don't error if $OPTS is not yet defined in .zinit-compinit call ([44765e0](https://github.com/zdharma-continuum/zinit/commit/44765e0bcb8d3f1ee3eb55286e33ad17b8c72a5e))
* filter by runtime detected CPU before compiled CPU ([#304](https://github.com/zdharma-continuum/zinit/issues/304)) ([a4dc13f](https://github.com/zdharma-continuum/zinit/commit/a4dc13f66a65c4fa52953104c13e44a7d7c0a945)), closes [#287](https://github.com/zdharma-continuum/zinit/issues/287)
* gh-r & plugin zunit tests ([dd12fce](https://github.com/zdharma-continuum/zinit/commit/dd12fce3f49db284de7cf18a03ef891cc46bc7cc))
* gh-r filters i686 (32 bit) for x86_64 ([#226](https://github.com/zdharma-continuum/zinit/issues/226)) ([57f0d82](https://github.com/zdharma-continuum/zinit/commit/57f0d82118ed626f04d4b9b8b26de48c9d7e0956)), closes [#225](https://github.com/zdharma-continuum/zinit/issues/225)
* gh-r logic ignores [36]86 assets ([#235](https://github.com/zdharma-continuum/zinit/issues/235)) ([d60638f](https://github.com/zdharma-continuum/zinit/commit/d60638f2217875056a061b3411c4bcc678dce5f6)), closes [#225](https://github.com/zdharma-continuum/zinit/issues/225) [#246](https://github.com/zdharma-continuum/zinit/issues/246) [#247](https://github.com/zdharma-continuum/zinit/issues/247)
* gh-r removes linux32 assets on 64 bit OS ([1864c0b](https://github.com/zdharma-continuum/zinit/commit/1864c0be09faa0e4d9a7c549cafed7d296d7517e))
* gh-r retrieves release data GH REST API  ([#373](https://github.com/zdharma-continuum/zinit/issues/373)) ([4a2a120](https://github.com/zdharma-continuum/zinit/commit/4a2a120b341793b1abaef5f12fbb4808277d8570)), closes [#374](https://github.com/zdharma-continuum/zinit/issues/374)
* modify regex in gh-r for assets to not consider for selection ([#244](https://github.com/zdharma-continuum/zinit/issues/244)) ([6ef8439](https://github.com/zdharma-continuum/zinit/commit/6ef84398b2c92073d88f440dfbfd554cb8e75343))
* more cleaning up urls ([672ae51](https://github.com/zdharma-continuum/zinit/commit/672ae514142b433708ea10486556fe3f0ba54e3e)), closes [#47](https://github.com/zdharma-continuum/zinit/issues/47)
* names of ctag Make target deps ([#407](https://github.com/zdharma-continuum/zinit/issues/407)) ([9987d5c](https://github.com/zdharma-continuum/zinit/commit/9987d5c781d4a95698ed649dc59b11c34006b1c1))
* package are broken again ([24f10f6](https://github.com/zdharma-continuum/zinit/commit/24f10f6367cbab6039bd0c1ca07dd9449bbc3557))
* permissions for PR labeler GH action workflow ([#236](https://github.com/zdharma-continuum/zinit/issues/236)) ([8a0d567](https://github.com/zdharma-continuum/zinit/commit/8a0d5678d1ee0eeed91d2c3a094578a2cd39ba04))
* read without -r is generally bad. ([00c70a4](https://github.com/zdharma-continuum/zinit/commit/00c70a434d50a1591bcdc73185150b2fdce96c77))
* remove curl option "--tcp-fastopen" which is not always available ([#299](https://github.com/zdharma-continuum/zinit/issues/299)) ([308c9d4](https://github.com/zdharma-continuum/zinit/commit/308c9d4cd82f3e41d2ae21ff31fba0dc4a7c6cb5))
* remove macOS 10.5 & 11 from test matrix ([c613193](https://github.com/zdharma-continuum/zinit/commit/c61319378df5b0deae68fc467b9a2449fcf67336))
* remove use less line ([4f87076](https://github.com/zdharma-continuum/zinit/commit/4f870766011d36c871d8afd07afe56733c8de76d))
* rename `docs` to `doc` to match doc dir ([#212](https://github.com/zdharma-continuum/zinit/issues/212)) ([3a7dc95](https://github.com/zdharma-continuum/zinit/commit/3a7dc95f02340fb56693ca0f304e31be8c8a9652))
* rm linux32 assets in aarch64/arm64 gh-r regex ([#414](https://github.com/zdharma-continuum/zinit/issues/414)) ([529aa20](https://github.com/zdharma-continuum/zinit/commit/529aa20f42a249f609b9e8248d6fd00d609a35ce))
* syntax error when checking for `realpath` command  ([#259](https://github.com/zdharma-continuum/zinit/issues/259)) ([05559eb](https://github.com/zdharma-continuum/zinit/commit/05559ebdbcda77622daaf3935d20fdf9b9c09c6c)), closes [#257](https://github.com/zdharma-continuum/zinit/issues/257)
* trigger for PR labeler GH action workflow ([#237](https://github.com/zdharma-continuum/zinit/issues/237)) ([49af866](https://github.com/zdharma-continuum/zinit/commit/49af86688bc8c5882744a679f9c0094e2f4c7fa6))
* typo & triggers in documentation workflow ([#308](https://github.com/zdharma-continuum/zinit/issues/308)) ([161d7c1](https://github.com/zdharma-continuum/zinit/commit/161d7c1ee1fc2bbb43442cd90b48e502bf62603f))
* unmatched "(" in windows gh-r patterns ([#280](https://github.com/zdharma-continuum/zinit/issues/280)) ([1f4ba5a](https://github.com/zdharma-continuum/zinit/commit/1f4ba5ae0ccf928d1914dc3a11d00393e0fd94a8))
* update `zdharma` to `zdharma-continuum` ([66b1700](https://github.com/zdharma-continuum/zinit/commit/66b17007523321f9afee91dbe75b487de5db4fec))
* update docs for new jq-check ([6207427](https://github.com/zdharma-continuum/zinit/commit/62074272563f88a32a701f56f914297930a9da19))
* use [*] inside arbitrary strings. ([73a8c92](https://github.com/zdharma-continuum/zinit/commit/73a8c92d43f57bca514e44b9fed14e941168c61f))
* workflow pkg mgmt due to base OS changes ([195f72d](https://github.com/zdharma-continuum/zinit/commit/195f72d54b80051fc71d1f73909f5dabe6745649))
* ziextract execs discovery regex ([#410](https://github.com/zdharma-continuum/zinit/issues/410)) ([105b38a](https://github.com/zdharma-continuum/zinit/commit/105b38a195e2a67eaba9d7a69bcef7738c57d12d))
* zunit install in GH workflow ([#412](https://github.com/zdharma-continuum/zinit/issues/412)) ([f4787dc](https://github.com/zdharma-continuum/zinit/commit/f4787dcac803ed9055c4032c516dba66737beebf))


### Features

* ability to set program for `zinit ls` to use ([#221](https://github.com/zdharma-continuum/zinit/issues/221)) ([bad7af3](https://github.com/zdharma-continuum/zinit/commit/bad7af3ae2d8aab18feb11a0251987fe3c08c31b)), closes [#170](https://github.com/zdharma-continuum/zinit/issues/170)
* add `-a` (actual time) to `zinit times` cmd ([#223](https://github.com/zdharma-continuum/zinit/issues/223)) ([450d3c1](https://github.com/zdharma-continuum/zinit/commit/450d3c10a8f6728ee8c76bfb99f777658b8d3f35))
* add `krew` and `prebuilt-ripgrep` gh-r zunit tests ([#267](https://github.com/zdharma-continuum/zinit/issues/267)) ([f25b4ae](https://github.com/zdharma-continuum/zinit/commit/f25b4ae2b9951bf0d1306a17ef512a1868211b78))
* add compile vim from source zunit test ([#232](https://github.com/zdharma-continuum/zinit/issues/232)) ([126528c](https://github.com/zdharma-continuum/zinit/commit/126528ccd50e98c0e71f06971ae16aceb571fb97))
* add configure"" ice ([#334](https://github.com/zdharma-continuum/zinit/issues/334)) ([40a46c6](https://github.com/zdharma-continuum/zinit/commit/40a46c6d2250af7e01d91b2f8ec3e01cf392c3d1))
* add GH action to remove old workflow logs ([#248](https://github.com/zdharma-continuum/zinit/issues/248)) ([6647bdc](https://github.com/zdharma-continuum/zinit/commit/6647bdc31c5b82378195ce71055099a7b36734a1))
* add PR labeler to show what parts of Zinit are changed ([#211](https://github.com/zdharma-continuum/zinit/issues/211)) ([42e83d7](https://github.com/zdharma-continuum/zinit/commit/42e83d7f99254c16e408f52848b914f7aa264372))
* add releases via semantic-release ([73542b4](https://github.com/zdharma-continuum/zinit/commit/73542b490981e43adca4a09b64c327fe811d01e1))
* add releases via semantic-release ([#415](https://github.com/zdharma-continuum/zinit/issues/415)) ([cfa2f0e](https://github.com/zdharma-continuum/zinit/commit/cfa2f0ebcd674706d5cb91533cf362f6f4ddd7ee))
* expand linted file types to markdown and shell ([96fe03f](https://github.com/zdharma-continuum/zinit/commit/96fe03f85baf8eae33270a09a5ca82f108f6cc25))
* **git-process-output:** simplify progress-bar ([#204](https://github.com/zdharma-continuum/zinit/issues/204)) ([c888917](https://github.com/zdharma-continuum/zinit/commit/c888917edbafa3772870ad1f320da7a5f169cc6f))
* update output messaging to be more informative ([047320a](https://github.com/zdharma-continuum/zinit/commit/047320a9234be4de8299ff4796e28e2363e77984))

# [v3.7.0](https://github.com/zdharma-continuum/zinit/compare/v3.1...v3.7.0)
