$ SET NOON
$ IF "''NML$COMMAND'" .NES. "" THEN NML$COMMAND
$ RUN SYS$SYSTEM:NML
