local level = {
  300, --map need xp up
	300,
	300,
	300,
	300,
  400,
	400,
	400,
	400,
	400,
	500,
	500,
	500,
	500,
	500,
	600,
	600,
	600,
	600,
	600,
  700,
	700,
  700,
  700,
	700,
  800,
  850,
  900,
  950,
  1000
}
level.groups={
  {one={win_xp=50,lose_xp=25,enterfee=100,prize=200}}, --map group get xp value
  {two={win_xp=100,lose_xp=35,enterfee=1000,prize=2000}},
  {three={win_xp=150,lose_xp=45,enterfee=5000,prize=10000}}
}

return level
