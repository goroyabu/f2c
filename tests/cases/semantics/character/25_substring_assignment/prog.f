      PROGRAM CHRDEF
      CHARACTER*5 TEXT
      TEXT = 'ABCDE'
      TEXT(2:4) = 'XYZ'
      WRITE (*, 100) TEXT
  100 FORMAT ('[', A5, ']')
      END
