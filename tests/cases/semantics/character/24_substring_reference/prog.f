      PROGRAM CHRREF
      CHARACTER*5 TEXT
      CHARACTER*3 PART
      TEXT = 'ABCDE'
      PART = TEXT(2:4)
      WRITE (*, 100) PART
  100 FORMAT ('[', A3, ']')
      END
