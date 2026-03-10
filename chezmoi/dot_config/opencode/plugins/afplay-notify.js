let lastPlayedAt = 0

export const AfplayNotifyPlugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      const shouldNotify =
        event.type === "permission.asked" ||
        event.type === "session.idle" ||
        event.type === "session.error"

      if (!shouldNotify) return

      const now = Date.now()
      if (now - lastPlayedAt < 2000) return
      lastPlayedAt = now

      await $`afplay /System/Library/Sounds/Glass.aiff`
    },
  }
}
