      PROGRAM FILSEQ
      INTEGER A, B, C
      OPEN (UNIT=21, FILE='records.dat', STATUS='NEW',
     1      ACCESS='SEQUENTIAL', FORM='FORMATTED')
      WRITE (21,100) 10
      WRITE (21,100) 20
      WRITE (21,100) 30
      CLOSE (21)
      OPEN (UNIT=21, FILE='records.dat', STATUS='OLD',
     1      ACCESS='SEQUENTIAL', FORM='FORMATTED')
      READ (21,100) A
      READ (21,100) B
      READ (21,100) C
      CLOSE (21)
      WRITE (*,200) A, B, C
  100 FORMAT (I2)
  200 FORMAT (SS,'[',I2,1X,I2,1X,I2,']')
      END
