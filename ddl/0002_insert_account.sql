INSERT INTO Account (email, sshKey, created)
VALUES ('messages@prettyrobots.com', 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAs73WEWWB4mTg32qWMoqNmrnOQN7ijjj6kloigxtpGPwuozAtqlsCGjh8xyXnvRYJm2BEaVoX5eNG1F2vHXZu2ZUwH8PISMMEXFf4+1NWRJ693Bq99n4mmY3f05spI8sBkVHCmSWwqW3q6aLjh02398tNLvl6rdDbJ6UANNV/7W/haXy7RgeXQwLEJHwFtzSslbjWcmYfebzex2ueFf87kf4GdYccnIJLM1xY0Fd9dmNhIA8HEpCbVE0Up1Rg2jms7WAjuc9qhem0Qo+ayXYZSDzxzVTCpZS7p0zUw6ZtYJfjI/B46HgFeRBm5wk95il+QEA6dzNIZTzhzrS+Na2m8Q== junk', CURRENT_TIMESTAMP())
\g
INSERT INTO Application (accountId, isHome, created)
VALUES (1, 1, CURRENT_TIMESTAMP())
\g
INSERT INTO Machine (hostname, created)
VALUES ('portoroz.prettyrobots.com', CURRENT_TIMESTAMP())
\g