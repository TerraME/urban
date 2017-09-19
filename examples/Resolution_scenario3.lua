--@example Resolution model with agents making decision considering the distance from household to workplace and the neighborhood similarity.

import("urban")

scenario3 = Resolution{strategy = "decideBoth"}
scenario3:run()