# Today backgrounds

Today uses photographs and a reproduction of an original painting. No AI-generated images are bundled.

Choose Settings → Appearance → Today background. The choice is saved with local preferences; existing installations default to Mountains. Switching phrases keeps the background fixed. All three assets work offline.

## Sources

| Background | Creator / work | Source | Rights |
| --- | --- | --- | --- |
| Mountains | m wrona, Snow-covered summit (published May 2, 2017) | [Unsplash](https://unsplash.com/photos/white-fogs-on-mountain-filled-with-snow-JG7KBXn-_Mc) | [Unsplash License](https://unsplash.com/license) |
| Ocean | Hannah Reding, Beach with gentle waves at pastel sunset (published September 3, 2025; Fujifilm X-T4) | [Unsplash](https://unsplash.com/photos/beach-with-gentle-waves-at-pastel-sunset-yVl4V7dUS2Y) | [Unsplash License](https://unsplash.com/license) |
| Water Lilies | Claude Monet, Water Lilies, 1906; Art Institute of Chicago, Mr. and Mrs. Martin A. Ryerson Collection, 1933.1157 | [Wikimedia Commons reproduction](https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Water_Lilies_-_1906,_Ryerson.jpg), [museum record](https://api.artic.edu/api/v1/artworks/16568) | Public domain (museum record: is_public_domain=true; Commons: PD-Art / Public Domain Mark) |

Sources and permissions checked September 13, 2026. Photographs are licensed for use within the app, not resold as standalone images. The settings screen includes creator credits and source links.

## Bundled files

- `Vow/Resources/Assets.xcassets/TodayMountains.imageset/today-mountains.jpg`
- `Vow/Resources/Assets.xcassets/TodayOcean.imageset/today-ocean.jpg`
- `Vow/Resources/Assets.xcassets/TodayWaterLilies.imageset/today-water-lilies.jpg`

Photo downloads use the source image with a 1600-pixel width and JPEG quality 85, without the Open Graph logo or overlays. The painting reproduction is proportionally resized to a 1600-pixel maximum edge at JPEG quality 85. No generative changes, recoloring, or retouching are applied. The picker shows each full composition; the Today background fills the screen and crops to fit its aspect ratio.

Asset URLs:

- https://images.unsplash.com/photo-1493767147706-462e7ec5ef11?fit=max&w=1600&q=85&fm=jpg
- https://images.unsplash.com/photo-1756894348500-3bba1c5e3f12?fit=max&w=1600&q=85&fm=jpg
- https://upload.wikimedia.org/wikipedia/commons/a/aa/Claude_Monet_-_Water_Lilies_-_1906%2C_Ryerson.jpg

## Reading treatment

A paper-colored veil and adaptive opacity soften the background without altering the bundled image. Light appearance uses 38% image opacity, dark uses 22%, and Increased Contrast uses 12%. The lower controls fade to the paper color. Reduce Transparency uses a solid paper background. The background has no animation, parallax, or network requests. Review availability refreshes every 30 seconds.

Vocabulary retains the original New York font. See [design system](DESIGN-SYSTEM.md) for the remaining text roles.

## Validation

On September 13, 2026, 28 unit tests and 3 UI tests passed on the iPhone 17 Pro Max simulator. Coverage includes background selection and persistence after relaunch, legacy preferences, large text, and the Today examples flow. Visually checked all three backgrounds on iPhone in light appearance, the full-image picker and credits, and Mountains on iPad. Physical-device appearance has not been checked.
