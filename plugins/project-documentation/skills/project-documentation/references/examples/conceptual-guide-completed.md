# Example: Completed Conceptual Guide

This is what a finished conceptual guide looks like. Notice how it explains *how to think* about the system without inventorying *what currently exists*. A reader who understands this guide can reason about unfamiliar situations — that's the test.

---

# Notification System: How to Think About It

## The Big Idea

The notification system is a **postal service** for the application. Other parts of the system drop messages into a mailbox (publish events), and the notification system figures out who needs to receive what, through which channel, and when. No other service needs to know the delivery details — they just announce that something happened.

## Key Ideas

### Events, Not Commands

Services don't say "send an email to user 42." They say "order 1234 was confirmed." The notification system decides what to do with that information — maybe it sends an email, maybe a push notification, maybe both, maybe nothing (if the user opted out). This decoupling means services never need to know about notification preferences, templates, or delivery channels.

### Channel Strategy

A notification can be delivered through multiple channels: email, in-app, push, SMS. Each channel has different characteristics — email is reliable but slow, push is fast but easily ignored, SMS is intrusive but high-urgency. The system picks the right channel(s) based on the notification type and the user's preferences. Think of channels as delivery methods, not alternatives.

### Template Resolution

Every notification type has templates for each channel. Templates are stored separately from the logic that decides when to send — this lets product and marketing update copy without touching code. Templates receive a data payload and produce rendered output. If you need to change what a notification *says*, you're looking at templates. If you need to change *when* or *whether* it sends, you're looking at event handlers.

### Delivery Guarantees

Notifications use at-least-once delivery. This means a user might occasionally receive a duplicate, but they'll never silently miss a notification. We chose this trade-off because a missed order confirmation is worse than a duplicate one. Idempotency keys prevent most visible duplicates, but the system is designed to tolerate them.

## The Typical Flow

```
  [Any Service]
       │
       │ publishes domain event
       ▼
  [Event Bus]
       │
       │ routes to notification handler
       ▼
  [Notification Engine]
       │
       ├─ resolves recipient preferences
       ├─ selects channels
       ├─ renders templates per channel
       │
       ▼
  [Channel Dispatchers]
       │
       ├── Email → SMTP provider
       ├── Push  → Push notification service
       ├── SMS   → SMS gateway
       └── In-App → WebSocket / polling
```

## Scope

### This System Handles
- Deciding which users receive which notifications
- Respecting user opt-in/opt-out preferences
- Rendering notification content from templates
- Dispatching through the appropriate channel(s)
- Retry and failure handling for delivery

### This System Does NOT Handle
- **Transactional emails** (password reset, email verification) — those are handled directly by the Identity service because they're critical-path and shouldn't be subject to preference filtering
- **Marketing campaigns and bulk sends** — those go through the marketing platform, which has its own audience targeting and compliance tooling
- **Real-time chat** — that's a separate system with different latency and persistence requirements

## Common Misconceptions

### "Can I use this system to send a one-off email to a specific user?"

Not directly. The notification system is event-driven — it reacts to things that happen, it doesn't accept ad-hoc send requests. If you need a notification to fire, publish the appropriate domain event. If no event type exists for your use case, that's a signal you may need to define a new one. See `src/events/` for the current catalog.

### "Why doesn't it just retry forever until delivery succeeds?"

Because some failures are permanent (invalid email address, deactivated push token) and infinite retries would waste resources and potentially annoy users with delayed stale notifications. The system retries with exponential backoff up to a configurable limit, then records the failure for observability. The failure is visible in the delivery dashboard but doesn't block anything else.

### "Why is SMS handled the same as email? Isn't it more urgent?"

SMS isn't inherently more urgent — urgency is a property of the *notification type*, not the *channel*. An order confirmation goes to email. A fraud alert goes to SMS. The event handler for each notification type decides which channels to use based on the situation. The channel dispatchers are deliberately channel-agnostic about urgency.

## Navigating the Code

For current implementation details:
- Event handlers: See `src/notifications/handlers/`
- Channel dispatchers: See `src/notifications/channels/`
- Template definitions: See `src/notifications/templates/`
- User preferences: See `src/notifications/preferences/`
- Configuration (retry limits, channel settings): See `config/notifications.schema.json`
