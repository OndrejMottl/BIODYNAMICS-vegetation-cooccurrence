# Shared base profiles

This folder is reserved for non-selectable shared profiles introduced only when all descendant profiles remain semantically identical to the versioned configuration reference.

The issue #151 structural migration does not introduce new base identifiers. The existing `default` profile remains the only shared base because adding an inheritance layer without demonstrated duplication would make navigation harder rather than clearer.

Any future base fragment must be listed exactly once in `Configuration/manifest.yml`, use `role: base`, remain non-selectable, and keep inheritance within the manifest's maximum depth.
