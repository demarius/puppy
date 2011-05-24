SELECT ds.id AS "dataStore__id",
       ds.applicationId AS "dataStore__applicationId",
       ds.dataServerId AS "dataStore__dataServerId",
       ds.alias AS "dataStore__alias",
       ds.password AS "dataStore__password",
       ds.modified AS "dataStore__modified",
       ds.created AS "dataStore__created",
       s.id AS "dataStore__dataServer__id",
       s.engine AS "dataStore__dataServer__engine",
       s.hostname AS "dataStore__dataServer__hostname",
       s.port AS "dataStore__dataServer__port",
       s.modified AS "dataStore__dataServer__modified",
       s.created AS "dataStore__dataServer__created",
       app.id as "dataStore__application__id",
       app.isHome as "dataStore__application__isHome",
       app.created as "dataStore__application__created",
       app.modified as "dataStore__application__modified",
       acc.id AS "dataStore__application__account__id",
       acc.email AS "dataStore__application__account__email",
       acc.sshKey AS "dataStore__application__account__sshKey",
       acc.created AS "dataStore__application__account__created",
       acc.modified AS "dataStore__application__account__modified"
  FROM DataStore AS ds
  JOIN DataServer AS s ON ds.dataServerId = s.id
  JOIN Application AS app ON ds.applicationId = app.id
  JOIN Account AS acc ON app.accountId = acc.id
 WHERE acc.id = $1
 ORDER
    BY app.id, ds.id
