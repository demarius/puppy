require.paths.unshift("/puppy/common/lib/node")

require("common/shell").sudo("/puppy/worker/sbin/user_config", process.argv.slice(2))
