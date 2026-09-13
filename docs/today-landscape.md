# Today backgrounds

Today uses photographs and a reproduction of an original painting. No AI-generated images are bundled.

Choose Settings → Appearance → Today background. The choice is saved with local preferences; existing installations default to Mountains. Switching phrases keeps the background fixed. All eight assets work offline. Settings → Appearance → Theme offers Light, Dark and System; System is the default for new and existing installations. Theme and background choices persist independently of learning progress.

## Sources

| Background | Creator / work | Source | Rights |
| --- | --- | --- | --- |
| Mountains | m wrona, Snow-covered summit (published May 2, 2017) | [Unsplash](https://unsplash.com/photos/white-fogs-on-mountain-filled-with-snow-JG7KBXn-_Mc) | [Unsplash License](https://unsplash.com/license) |
| Ocean | Hannah Reding, Beach with gentle waves at pastel sunset (published September 3, 2025; Fujifilm X-T4) | [Unsplash](https://unsplash.com/photos/beach-with-gentle-waves-at-pastel-sunset-yVl4V7dUS2Y) | [Unsplash License](https://unsplash.com/license) |
| Water Lilies | Claude Monet, Water Lilies, 1906; Art Institute of Chicago, Mr. and Mrs. Martin A. Ryerson Collection, 1933.1157 | [Wikimedia Commons reproduction](https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Water_Lilies_-_1906,_Ryerson.jpg), [museum record](https://api.artic.edu/api/v1/artworks/16568) | Public domain (museum record: is_public_domain=true; Commons: PD-Art / Public Domain Mark) |

Sources and permissions checked September 13, 2026. Photographs are licensed for use within the app, not resold as standalone images. The settings screen includes creator credits and source links.

## Additional photographs (September 13, 2026)

| Background | Creator | Source | Asset |
| --- | --- | --- | --- |
| Misty Forest | Todd Aarnes | [Morning Reflections](https://unsplash.com/photos/trees-with-fog-wmFTP3vbYKU) | TodayForest |
| Alpine Lake | Andrew Svk | [Foggy morning on a Big Beehive Trail](https://unsplash.com/photos/a-green-lake-surrounded-by-trees-and-fog-9lLcLf490nM) | TodayLake |
| White Dunes | Simon Schwyter | [White Sands](https://unsplash.com/photos/expansive-white-sand-dunes-under-a-pale-sky-mK5OE9bgg1Q) | TodayDunes |
| Misty Hills | Ricardo Gomez Angel | [Mist over hilly countryside](https://unsplash.com/photos/landscape-photo-of-mountain-covered-with-fog-tNYTM5_Fpes) | TodayHills |
| Clouds | Billy Huynh | [Cloudy sky at daytime](https://unsplash.com/photos/cloudy-sky-at-daytime-v9bnfMCyKbg) | TodayClouds |

Each source identifies its photo as free under the [Unsplash License](https://unsplash.com/license), checked on September 13, 2026. Creator credits and source links are included in the picker. New files are JPEGs with a maximum 1600-pixel edge at quality 85; original proportions and colors are retained.

## Bundled files

- `Vow/Resources/Assets.xcassets/TodayMountains.imageset/today-mountains.jpg`
- `Vow/Resources/Assets.xcassets/TodayOcean.imageset/today-ocean.jpg`
- `Vow/Resources/Assets.xcassets/TodayWaterLilies.imageset/today-water-lilies.jpg`

Photo downloads use the source image with a 1600-pixel width and JPEG quality 85, without the Open Graph logo or overlays. The painting reproduction is proportionally resized to a 1600-pixel maximum edge at JPEG quality 85. No generative changes, recoloring, or retouching are applied. The picker uses equal 4:3 thumbnail canvases with centered fill crops. All tiles share the same caption height, selection position, corner radius and gaps. It adapts its column count to available width and Dynamic Type. The selected-image preview uses a fixed 4:3 canvas and fits the full original composition inside it. The Home background fills the screen and crops to fit its aspect ratio.

Asset URLs:

- https://images.unsplash.com/photo-1493767147706-462e7ec5ef11?fit=max&w=1600&q=85&fm=jpg
- https://images.unsplash.com/photo-1756894348500-3bba1c5e3f12?fit=max&w=1600&q=85&fm=jpg
- https://upload.wikimedia.org/wikipedia/commons/a/aa/Claude_Monet_-_Water_Lilies_-_1906%2C_Ryerson.jpg

## Reading treatment

A paper-colored veil and adaptive opacity soften the background without altering the bundled image. Light appearance uses 38% image opacity, dark uses 22%, and Increased Contrast uses 12%. The lower controls fade to the paper color. Reduce Transparency uses a solid paper background. The background has no animation, parallax, or network requests. Review availability refreshes every 30 seconds.

Vocabulary retains the original New York font. See [design system](DESIGN-SYSTEM.md) for the remaining text roles.

## Validation

On September 13, 2026, 28 unit tests and 3 UI tests passed on the iPhone 17 Pro Max simulator. Coverage includes background selection and persistence after relaunch, legacy preferences, large text, and the Today examples flow. Visually checked all three backgrounds on iPhone in light appearance, the full-image picker and credits, and Mountains on iPad. Physical-device appearance has not been checked.


## Appearance expansion validation

The five additional source images were inspected visually before inclusion. The persistence and legacy-data tests now check all three theme choices and a new background without changing saved expressions or learning events. `AppearanceUITests` exercises theme changes across the settings sheet and Home, relaunch persistence, equal grid tile sizes and all five new background selections. Current-run results are in `.build/appearance/`; historical screenshots above do not validate the expanded grid.

The September 13 appearance build (`.build/appearance/build.log`) succeeded, and all 76 Swift package tests passed (`tests.log`). All eight asset entries resolve to valid JPEGs; five new photographs were visually inspected. The iOS 26.3 QA simulator finished booting, but test execution did not begin and even `simctl listapps` timed out after 20 seconds. The pending UI test was interrupted; no expanded-grid screenshots or runtime theme-switch success is claimed. The final build remains available in `.build/japanese-settings/DerivedData/Build/Products/Debug-iphonesimulator/Vow.app`.
