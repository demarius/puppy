UPDATE LocalUser
   SET ready = TRUE
 WHERE machineId = (SELECT id FROM Machine WHERE hostname = $1) AND id = $2
