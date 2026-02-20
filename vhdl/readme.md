CONFIGREG :

- Unlock access with : poke 67,89
- Place value in 66 (poke 66,value)

-- bit 0 -> Inverse Video (char)
-- bit 1 -> Inverse Video (border)
-- bit 2 -> NoWait mod(wait signal on Pin 22 - unused for 50Hz)
-- bit 3 -> M1Not
-- bit 4 -> Reset nmi counter : intack (default) or vsync (Metropolis compatible)
-- bit 6/7 -> Clock 3.25 (6.5 / 13 / 26)
