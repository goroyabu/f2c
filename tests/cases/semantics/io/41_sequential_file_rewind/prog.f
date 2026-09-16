      PROGRAM FILREW
      INTEGER A, B
      OPEN (UNIT=22, FILE='rewind.dat', STATUS='NEW',
     1      ACCESS='SEQUENTIAL', FORM='FORMATTED')
      WRITE (22,100) 41
      WRITE (22,100) 42
      REWIND (UNIT=22)
      READ (22,100) A
      READ (22,100) B
      CLOSE (22)
      WRITE (*,200) A, B
  100 FORMAT (I2)
  200 FORMAT (SS,'[',I2,1X,I2,']')
      END
