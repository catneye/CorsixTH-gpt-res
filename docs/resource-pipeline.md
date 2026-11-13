# Resource pipeline notes

Target runtime: CorsixTH 0.70.2.

The engine loads custom animation data from CTHG resources through its custom graphics mapping. Named animations are queried through the animation manager and return direction-specific animation IDs.

We will document the exact binary layout and loading sequence here as we verify each step against the 0.70.2 source. Do not treat PNG sprite sheets or individual frame images as directly loadable game animations: they must be converted into the engine's expected resource format.
