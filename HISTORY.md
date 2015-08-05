# 1.3.3 - 05/08/2015
* Fixed bug with get_timer

# 1.3.2 - 03/08/2015
* Fixed bug with log_cmd that prevented command with options to work as
    expexted

# 1.3.1 - 29/07/2015
* Added better elapsed time display with [pretty-hrtime.sh]
    (https://github.com/posva/pretty-hrtime.sh)
* Removed unused local variables
* Removed bc dependency :relieved:

# 1.3.0 - 27/07/2015
* Added smart cleanup
    * Added options to the finish method
* `tmp_cleanup` method
* Added history.md

# 1.2.0 - 01/06/2015
* Added overwrite option in `log_task`
* Added last modification date in script

# 1.1.0 - 06/02/2015
* Added a better in progress indicator
* Ability to customize the progress indicator
* Actually fixed bug with negative elapsed time

# 1.0.1 - 02/02/2015
* Fixed bug with negative elapsed time
* Don't overwrite tasks with the same name. Instead add an increasing number at
    the end

# 1.0.0 - 30/01/2015
* Initial release
