--@example Resolution model with agents making decision considering only the neighborhood similarity.

import("urban")

scenario2 = Resolution{strategy = "decideNeighborhood"}
scenario2:run()