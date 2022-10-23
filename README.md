# lua-aux
Various auxiliary lua modules for everyday use

Some examples:

Vector math
```
require "vector"
require "matrix"

x=vector{1,0,0}
Rz=matrix.rotateZ(math.pi/3,3)
print("Rz",Rz)
x1=Rz*x
print("x1",x1)
```
output:
```
Rz	matrix{
	{  0.5000, -0.8660,  0.0000},
	{  0.8660,  0.5000,  0.0000},
	{  0.0000,  0.0000,  1.0000},
}
x1	vector{0.5,0.866,0}
```

Complex numbers
```
require "complex"
require "matrix"

i=complex{0,1}
print(i,i*i,complex{-1}^0.25)

s1=matrix{ {0, 1}, {1, 0} }
s2=matrix{ {0,-i}, {i, 0} }
s3=matrix{ {1, 0}, {0,-1} }
print("s1*s2",s1*s2)
print(" i*s3",i*s3)
```
output:
```
complex{0,1}	complex{-1,0}	complex{0.7071,0.7071}
s1*s2	matrix{
	{complex{  0.0000,  1.0000},complex{  0.0000,  0.0000}},
	{complex{  0.0000,  0.0000},complex{  0.0000, -1.0000}},
}
 i*s3	matrix{
	{complex{  0.0000,  1.0000},complex{  0.0000,  0.0000}},
	{complex{  0.0000,  0.0000},complex{  0.0000, -1.0000}},
}
```

