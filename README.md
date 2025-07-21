# CaracalSteg (Library and CLI)
This project is part of the code base for my undergraduate thesis project at the University of Virginia in 2021. The goal of the project is to create a user-friendly way to steganographically embed hidden text into JPEG files which survives lossy JPEG recompression (such as when uploading to social media).

- [Library Code](https://github.com/Rayhawk11/caracal_steg) - Contains the core algorithm, library, and a command line interface.
- [Flutter UI Code](https://github.com/Rayhawk11/caracal_steg_ui) - Contains the minimum Flutter UI implementation.

Please see the [full report](https://doi.org/10.18130/tw10-fd71) for details.

## Status and Caveats
This project is not being actively developed, monitored, or maintained. It may not work with current versions of Dart and Flutter. At the time, it was an attempt to create a user-friendly minimum viable product in a short amount of time. The code does not reflect my current professional standards for documentation and best practices, but it remains a project I'm proud of for turning academic research into a real-world minimally usable app.

## Acknowledgments
Please note that this is an implementation project, not a research project; the techniques presented are not my own. The primary algorithm used in this impelmentation was created by [Xu, J., Sung, A. H., Shi, P., & Liu, Q. (2004)](https://doi.org/10.1109/ITCC.2004.1286737). See also the full report linked above for additional acknwoledgements.

Special thanks to [Professor David Wu](https://engineering.virginia.edu/faculty/david-wu), my technical advisor, without whom this project would not have been a success.

Also shoutout to [Ilia Gyrdymov](https://github.com/gyrdym) and the [ml_linalg](https://github.com/gyrdym/ml_linalg) project which was a core library in this implementation. Without the project's wonderful support in quickly resolving an [issue](https://github.com/gyrdym/ml_linalg/issues/100), this project would have been much harder!