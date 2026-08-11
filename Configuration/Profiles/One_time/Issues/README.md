# One-time issue profiles

These fragments preserve configurations created for a bounded historical issue, benchmark, or implementation comparison. They are not supported production choices.

Each profile records its related issue, dedicated runner, frozen or archived status, and retirement criterion in `_profile`. Normal pipeline runners reject the `one_time` role. A dedicated historical runner must authorize it explicitly.

Issue #138 profiles preserve the accepted staged cross-validation benchmark inputs required by issue #141. The issue #143 profile preserves the shared-MEM scalability comparison. They may be archived only when their recorded retirement criteria are satisfied.
