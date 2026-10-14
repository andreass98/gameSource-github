CollisionMask = {}
CollisionMask.ALL = 4294967295
CollisionMask.DEFAULT = 255
CollisionMask.ANIMAL_MULTIPLAYER = CollisionFlag.ANIMAL
CollisionMask.ANIMAL_SINGLEPLAYER = CollisionFlag.PLAYER + CollisionFlag.ANIMAL
CollisionMask.ANIMAL_POSITIONING = CollisionFlag.TERRAIN + CollisionFlag.ANIMAL_POSITIONING
CollisionMask.LANDSCAPING = CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.ANIMAL
CollisionMask.LEVELING = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.ANIMAL