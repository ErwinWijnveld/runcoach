<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RunCoach Invitation</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #faf8f4; color: #1a1a1a; margin: 0; padding: 2rem; }
        .container { max-width: 480px; margin: 4rem auto; background: white; border-radius: 12px; padding: 2rem; box-shadow: 0 4px 12px rgba(0,0,0,0.05); text-align: center; }
        h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
        .org { font-weight: bold; }
        .btn { display: inline-block; background: #4f46e5; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; margin-top: 1.5rem; font-weight: 500; }
        .btn-secondary { background: #e5e7eb; color: #1a1a1a; margin-top: 0.5rem; }
        .footer { margin-top: 1rem; color: #6b7280; font-size: 0.875rem; }
        .invalid { color: #dc2626; }
    </style>
</head>
<body>
    <div class="container">
        @if ($membership === null)
            <h1>Invitation not found</h1>
            <p class="invalid">This invitation link is invalid or has expired.</p>
            <p class="footer">If you believe this is a mistake, ask the person who invited you to resend the invitation.</p>
        @else
            <h1>You're invited to join</h1>
            <p class="org">{{ $membership->organization->name }}</p>
            <p>as a <strong>{{ $membership->role->label() }}</strong></p>

            <a href="runcoach://invites/{{ $token }}" class="btn">Open in RunCoach app</a>
            <br>
            <a href="https://apps.apple.com/" class="btn btn-secondary">Don't have the app?</a>

            <p class="footer">This invitation expires in 14 days.</p>
        @endif
    </div>
</body>
</html>
