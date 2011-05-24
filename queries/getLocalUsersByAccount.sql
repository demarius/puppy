SELECT lu.machineId AS "localUser__machineId",
       lu.id AS "localUser__id",
       lu.ready AS "localUser__ready",
       lu.policy AS "localUser__policy",
       lu.modified AS "localUser__modified",
       lu.created AS "localUser__created",
       m.id AS "localUser__machine__id",
       m.hostname AS "localUser__machine__hostname",
       m.modified AS "localUser__machine__modified",
       m.created AS "localUser__machine__created",
       app.id as "localUser__application__id",
       app.isHome as "localUser__application__isHome",
       app.created as "localUser__application__created",
       app.modified as "localUser__application__modified",
       acc.id AS "localUser__application__account__id",
       acc.email AS "localUser__application__account__email",
       acc.sshKey AS "localUser__application__account__sshKey",
       acc.created AS "localUser__application__account__created",
       acc.modified AS "localUser__application__account__modified"
  FROM LocalUser AS lu
  JOIN Machine AS m ON lu.machineId = m.id
  JOIN ApplicationLocalUser AS alu ON alu.machineId = lu.machineId AND alu.localUserId = lu.id
  JOIN Application AS app ON alu.applicationId = app.id
  JOIN Account AS acc ON app.accountId = acc.id
 WHERE acc.id = $1
 ORDER
    BY app.id, alu.id 
