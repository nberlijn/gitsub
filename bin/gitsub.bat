@echo off

:args

	if "%~1" == "--h" goto usage
	
	if "%~1" == "" goto usage
	
	if "%~1" == "add" goto add
	if "%~1" == "init" goto init
	if "%~1" == "commit" goto commit

	shift goto args

:add

	if "%~2" == "--h" echo usage: gitsub add -u [username] -r [repository] -m [submodules] & goto end
	
	if "%~2" == "" if "%~3" == "" goto usage
	if "%~4" == "" if "%~5" == "" goto usage
	if "%~6" == "" if "%~7" == "" goto usage
	
	if "%~2" == "-u" set username=%~3
	if "%~4" == "-r" set repository=%~5
	if "%~6" == "-m" set submodules=%~7 

	goto create
	
	shift goto add
	
:init

	if "%~2" == "--h" echo usage: gitsub init -u [username] -r [repository] -d [directory] & goto end
	
	if "%~2" == "" if "%~3" == "" goto usage
	if "%~4" == "" if "%~5" == "" goto usage
	if "%~6" == "" if "%~7" == "" goto usage
	
	if "%~2" == "-u" set username=%~3
	if "%~4" == "-r" set repository=%~5
	if "%~6" == "-d" set directory=%~7

	goto build

	shift goto init

:commit

	if "%~2" == "--h" echo usage: gitsub -m [message] & goto end
	
	if "%~2" == "" if "%~3" == "" goto usage
	
	if "%~2" == "-m" set message=%~3

	goto push

	shift goto commit

:usage

	echo usage: gitsub [command] [--h]
	echo.
	echo commands:
	echo.
	echo    gitsub add       Add new submodules to a GitHub repository
	echo    gitsub init      Clone from GitHub and build a local submodules repository
	echo    gitsub commit    Commit and push from a submodule to GitHub

	goto end

:create

	set directory=%repository%-temp

	git clone https://github.com/%username%/%repository%.git %directory%

	cd %directory%

	for %%s in (%submodules%) do (

		set message=%%s submodule added
	
		git checkout --orphan %%s
		git rm --cached -r *
		git add .gitignore
		git commit -m "%message%"
		git push origin %%s

		git checkout -f master
		git submodule add -b %%s https://github.com/%username%/%repository%.git %%s
		git commit -m "%message%"
		git push origin master

	)

	cd ..

	rd /s /q %directory%

	goto end

:build

	git clone https://github.com/%username%/%repository%.git %directory%
	
	cd %directory%

	git submodule init
	git submodule update

	for /f "tokens=4 delims=/" %%b in ('"git for-each-ref --format=%%(refname) refs/remotes"') do (

		if not %%b == HEAD if not %%b == master if not %%b == gh-pages (

			cd %%b

			git checkout -b %%b

			cd ..

		)

	)

	goto end

:push

	for /f %%b in ('"git rev-parse --abbrev-ref HEAD"') do (

		git add *
		git commit -m "%message%"
		git push origin %%b

		cd ..

		git add *
		git commit -m "%message%"
		git push origin master

	)

	goto end

:end

	break
