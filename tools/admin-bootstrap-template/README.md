# One-time Kaylo admin bootstrap template

This is not a deployed Supabase function. An authorized operator may temporarily
copy index.ts and bootstrap.ts into a uniquely named function directory after
the admin migration passes verification.

Required existing server configuration: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
and FIREBASE_SERVICE_ACCOUNT_B64. Add a fresh random 32-byte value encoded as 64
hexadecimal characters in KAYLO_ADMIN_BOOTSTRAP_SECRET. Never put the value in
the website, repository, logs or chat.

Invoke with POST, header x-kaylo-admin-bootstrap-secret, and JSON
{"operation":"prepare_admin_setup"}. Only kayloapp@gmail.com is supported.
Browser origins are refused. Existing Firebase passwords and disabled accounts
are never changed. Existing inactive or conflicting administrator entries
require manual review.

The response contains email, uid, setup_url and created (whether Firebase
account creation was attempted). The setup URL is sensitive: give it privately
to the account owner. Firebase returnOobLink:true creates the link without
sending email. The password changes only when the owner completes that link.

Remove the temporary function and bootstrap secret immediately after use. Keep
the template outside supabase/functions and routine deployment configuration.
Tests use fakes and never contact Google, Supabase or email services.
