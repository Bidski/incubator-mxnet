---

Can't build cython modules

```
/usr/bin/cmake -E env MXNET_LIBRARY_PATH=/home/bidski/Projects/mxnet/build/libmxnet.so /usr/bin/python3 setup.py build_ext --inplace --with-cython
free(): invalid pointer
Child aborted
```

---

Can't properly generate `mxnet/op.h`

```
Running: OpWrapperGenerator.py
argument "begin" of operator "slice" has unknown type "tuple of <>, required"
argument "end" of operator "slice" has unknown type "tuple of <>, required"
argument "step" of operator "slice" has unknown type "tuple of <>, optional, default=[]"
argument "end" of operator "slice_axis" has unknown type ", required"
```

