Usage
=====

.. _installation:

Requirements
------------

To use the function, we need **MATLAB Bioinformatics Toolbox**:

and also, ``mat2tiles`` function is needed

.. code-block:: console





The ``Int`` is an image ``"innerSheath", "outerSheath" and "lens"``, should be defined, otherwise, py:func:`segmentation`
will raise an error.

For example: 

function [mask, IndexInnerSheath,IndexOuterSheath,IndexBallLens] = SegmentationGraphTheoryLowProfile2023(Int,innerSheath,outerSheath,lens)


