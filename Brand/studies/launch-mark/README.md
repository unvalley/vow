# Launch mark, turning in depth

**Not adopted.** Studied on 2026-09-21 and set aside: the app ships a static
launch screen, the mark on black, and nothing else. These files are the record
of the turning version, outside every build target.

The icon artwork is a raster with no model behind it. Seen face-on it is a fat
tube swept along a bent spine, two lobes joined by a neck, and fitting that
silhouette to `Izzy.icon/Assets/mark.png` leaves 1% of the mark's area
unexplained. `make_launch_mark.swift` turns the fit into a solid: the balls
along the spine as a distance field, softened so near-coincident surfaces run
together while the folds stay folds, then meshed, with the folds' shade baked
into the vertices. Depth is a guess, since the artwork only shows the front.

- `make_launch_mark.swift` writes `LaunchMark.scn` (mark, lights, camera) and
  renders its resting pose as the launch screen's still, so the still and the
  scene that takes over from it are one picture. Its header has the commands.
- `LaunchMarkScene.swift` holds the constants the generator and the app share:
  frame size, node name and the turn's axis.
- `LaunchView.swift` is the SwiftUI cover: the still, then a SceneKit view over
  it that turns the solid once on a spring and reports when it has settled.

To adopt it: generate into `Izzy/Resources/LaunchMark.scn` and
`Izzy/Resources/Assets.xcassets/LaunchMark.imageset`, move the two app files to
`Izzy/Views`, exclude the scene in `Package.swift`, and overlay
`LaunchView { launching = false }` on `RootView` while a `launching` state is
true, skipping it under `--ui-tests`. On the iPhone 17 Pro simulator the scene
loaded in 40 ms and drew its first frame 140 ms after the cover appeared; it
has not run on a device. The turn adds about 1.5 s before Home.
