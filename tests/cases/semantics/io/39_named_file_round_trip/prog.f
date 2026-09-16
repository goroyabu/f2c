      PROGRAM FILERT
      INTEGER IVAL
      REAL RVAL
      CHARACTER*5 TEXT
      OPEN (UNIT=20, FILE='roundtrip.dat', STATUS='NEW',
     1      ACCESS='SEQUENTIAL', FORM='FORMATTED')
      WRITE (20,100) 12, 3.5, 'HELLO'
      CLOSE (20)
      OPEN (UNIT=20, FILE='roundtrip.dat', STATUS='OLD',
     1      ACCESS='SEQUENTIAL', FORM='FORMATTED')
      READ (20,100) IVAL, RVAL, TEXT
      CLOSE (20)
      WRITE (*,200) IVAL, RVAL, TEXT
  100 FORMAT (I3,F5.1,A5)
  200 FORMAT (SS,'[',I2,'] [',F3.1,'] [',A5,']')
      END
