$ !
$ ! Network VMSmail command file
$ !
$ SET NOON
$ IF "''MAIL$COMMAND'" .NES. "" THEN MAIL$COMMAND
$ MAIL
$ SET ON
$ EXIT 1
