      PROGRAM FMTOUT
      INTEGER IVAL
      REAL RVAL
      LOGICAL LVAL
      CHARACTER*5 TEXT
      IVAL = 7
      RVAL = 2.5
      LVAL = .TRUE.
      TEXT = 'AB'
      WRITE (*,100) IVAL, RVAL, LVAL, TEXT
  100 FORMAT (SS,'[',I5.3,'] [',F6.2,'] [',L2,'] [',A5,']')
      END
