require.paths.unshift("/puppy/common/lib/node")

require("common/shell").sudo("/puppy/worker/sbin/user_authorize", process.argv.slice(2))
