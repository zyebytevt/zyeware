// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.ecs.component.transform;

import std.algorithm : remove;
import std.string : format;
import std.exception : enforce;

import inmath.linalg;

import zyeware.common;

/// The Transform2DComponent, if attached, will give an entity a 2D
/// world transformation. This is a base component necessary for most
/// other components.
@component
struct Transform2DComponent
{
private:
    Vector2f mPosition = void;
    float mRotation = void;
    Vector2f mScale = void;
    int mZIndex = void;

    Matrix4f mLocalMatrix = void, mGlobalMatrix = void;

    Transform2DComponent* mParent;
    Transform2DComponent*[] mChildren;

    void recalculateLocalMatrix() pure
    {
        mLocalMatrix = Matrix4f.translation(position.x, position.y,
                mZIndex / 100f) * Matrix4f.rotation(-rotation, Vector3f(0, 0,
                1)) * Matrix4f.scaling(scale.x, scale.y, 1);

        recalculateGlobalMatrix();
    }

    void recalculateGlobalMatrix() pure
    {
        if (mParent)
            mGlobalMatrix = mParent.mGlobalMatrix * mLocalMatrix;
        else
            mGlobalMatrix = mLocalMatrix;

        foreach (Transform2DComponent* child; mChildren)
            child.recalculateGlobalMatrix();
    }

public:
    /// Params:
    ///     position = The position of this transform.
    ///     rotation = The rotation of this transform, in radians.
    ///     scale = The scale of this transform.
    ///     zIndex = The layer of the transform. Lower values are above others.
    this(in Vector2f position, float rotation = 0, in Vector2f scale = Vector2f(1), int zIndex = 0) pure
    {
        mPosition = position;
        mRotation = rotation;
        mScale = scale;
        mZIndex = zIndex;

        recalculateLocalMatrix();
    }

	/// Calculates a transformation matrix with this transform's properties alone.
    /// 
	/// Returns: The local transformation matrix.
    Matrix4f localMatrix() pure const nothrow
    {
        return mLocalMatrix;
    }

	/// Calculates a transformation matrix and multiplies it with the ones
	/// of it's parents.
    /// 
	/// Returns: The global transformation matrix.
    Matrix4f globalMatrix() pure const nothrow
    {
        return mGlobalMatrix;
    }

	/// The parent of this transform.
    /// 
	/// Throws: `ComponentException` in case of cyclic transform parenting.
    Transform2DComponent* parent() pure nothrow
    {
        return mParent;
    }

    /// ditto
    void parent(Transform2DComponent* parent) pure
    {
        // Check if we ourselves are a parent of our future parent
        Transform2DComponent* check = parent;
        while (check)
        {
            enforce!ComponentException(check != &this,
                    "Cyclic Transform2D parenting! (&this = %08X, parent = %08X).".format(&this,
                        parent));
            check = check.mParent;
        }

        // If a parent exists, we need to remove us from there.
        if (mParent)
        {
            for (size_t i; i < mParent.mChildren.length; ++i)
                if (mParent.mChildren[i] == &this)
                {
                    mParent.mChildren.remove(i);
                    break;
                }
        }

        mParent = parent;
        if (mParent) // In case parent is not null
        {
            auto x = &this;
            parent.mChildren ~= x;
        }

        recalculateGlobalMatrix();
    }

    /// Returns all children of this transform.
    const(Transform2DComponent*[]) children() const pure nothrow 
    {
        return mChildren;
    }

    /// The position of this transform.
    Vector2f position() nothrow pure const 
    {
        return mPosition;
    }

    /// ditto
    void position(in Vector2f value) pure
    {
        mPosition = value;
        recalculateLocalMatrix();
    }

    /// The global position of this transform.
    Vector2f globalPosition() nothrow pure const 
    {
        if (mParent)
            return (mParent.globalMatrix * Vector4f(mPosition, 0, 1)).xy;
        else
            return mPosition;
    }

    /// ditto
    void globalPosition(in Vector2f value) pure
    {
        if (mParent)
            mPosition = (mParent.globalMatrix.inverse * Vector4f(value, 0, 1)).xy;
        else
            mPosition = value;
        
        recalculateLocalMatrix();
        recalculateGlobalMatrix();
    }

    /// The rotation of this transform, in radians.
    float rotation() nothrow  pure const
    {
        return mRotation;
    }

    /// ditto
    void rotation(float value) pure
    {
        mRotation = value;
        recalculateLocalMatrix();
    }

    float globalRotation() nothrow pure const
    {
        if (mParent)
            return mParent.globalRotation() + mRotation;
        else
            return mRotation;
    }

    void globalRotation(float value) pure
    {
        // TODO: Check with unittest!
        if (mParent)
            mRotation = value - mParent.globalRotation;
        else
            mRotation = value;
    }

    /// The scaling of this transform.
    Vector2f scale() nothrow  pure const
    {
        return mScale;
    }

    /// ditto
    void scale(in Vector2f value) pure
    {
        mScale = value;
        recalculateLocalMatrix();
    }

    /*Vector2f globalScale() nothrow pure const
    {
        if (mParent)
            return mParent.globalScale * mScale;
        else
            return mScale;
    }*/

    /// The layer of the transform. Lower values are above others.
    int zIndex() nothrow  pure const
    {
        return mZIndex;
    }

    /// ditto
    void zIndex(int value) pure
    {
        mZIndex = value;
        recalculateLocalMatrix();
    }
}

// ==============================================================================

/// The Transform3DComponent, if attached, will give an entity a 3D
/// world transformation. This is a base component necessary for most
/// other components.
@component
struct Transform3DComponent
{
private:
    Vector3f mPosition = void;
    quat mRotation = void;
    Vector3f mScale = void;

    Matrix4f mLocalMatrix = void, mGlobalMatrix = void;

    Transform3DComponent* mParent;
    Transform3DComponent*[] mChildren;

    void recalculateLocalMatrix() pure
    {
        mLocalMatrix = Matrix4f.translation(position.x, position.y,
                position.z) * rotation.toMatrix!(4,
                4) * Matrix4f.scaling(scale.x, scale.y, scale.z);

        recalculateGlobalMatrix();
    }

    void recalculateGlobalMatrix() pure
    {
        if (mParent)
            mGlobalMatrix = mParent.mGlobalMatrix * mLocalMatrix;
        else
            mGlobalMatrix = mLocalMatrix;

        foreach (Transform3DComponent* child; mChildren)
            child.recalculateGlobalMatrix();
    }

public:
    /// Params:
    ///     position = The position of this transform.
    ///     rotation = The rotation of this transform, represented as a quaternion.
    ///     scale = The scaling of this transform.
    this(in Vector3f position, in quat rotation = quat.identity, in Vector3f scale = Vector3f(1)) pure
    {
        mPosition = position;
        mRotation = rotation;
        mScale = scale;

        recalculateLocalMatrix();
    }
    
	/// Calculates a transformation matrix with this transform's properties alone.
    ///
	/// Returns: The local transformation matrix.
    Matrix4f localMatrix() pure const nothrow
    {
        return mLocalMatrix;
    }

	/// Calculates a transformation matrix and multiplies it with the ones
	/// of it's parents.
    /// 
	/// Returns: The global transformation matrix.
    Matrix4f globalMatrix() pure const nothrow
    {
        return mGlobalMatrix;
    }
    
	/// The parent of this transform.
    /// 
	/// Throws: `ComponentException` in case of cyclic transform parenting.
    Transform3DComponent* parent() pure nothrow
    {
        return mParent;
    }

    /// ditto
    void parent(Transform3DComponent* parent)
    {
        // Check if we ourselves are a parent of our future parent
        Transform3DComponent* check = parent;
        while (check)
        {
            enforce!ComponentException(check != &this,
                    "Cyclic Transform3D parenting! (&this = %08X, parent = %08X).".format(&this,
                        parent));
            check = check.mParent;
        }

        // If a parent exists, we need to remove us from there.
        if (mParent)
        {
            for (size_t i; i < mParent.mChildren.length; ++i)
                if (mParent.mChildren[i] == &this)
                {
                    mParent.mChildren.remove(i);
                    break;
                }
        }

        mParent = parent;
        if (mParent) // In case parent is not null
        {
            auto x = &this;
            parent.mChildren ~= x;
        }

        recalculateGlobalMatrix();
    }

    /// Returns all children of this transform.
    const(Transform3DComponent*[]) children() const pure nothrow 
    {
        return mChildren;
    }

    /// The position of this transform.
    Vector3f position() pure const nothrow 
    {
        return mPosition;
    }

    /// ditto
    void position(in Vector3f value) pure
    {
        mPosition = value;
        recalculateLocalMatrix();
    }

    /// The global position of this transform.
    Vector3f globalPosition() nothrow pure const 
    {
        if (mParent)
            return (mParent.globalMatrix * Vector4f(mPosition, 1)).xyz;
        else
            return mPosition;
    }

    /// ditto
    void globalPosition(in Vector3f value) pure
    {
        if (mParent)
            mPosition = (mParent.globalMatrix.inverse * Vector4f(value, 1)).xyz;
        else
            mPosition = value;
        
        recalculateGlobalMatrix();
    }

    /// The rotation of this transform, as a quaternion.
    quat rotation() nothrow  pure const
    {
        return mRotation;
    }

    /// ditto
    void rotation(in quat value) pure
    {
        mRotation = value;
        recalculateLocalMatrix();
    }

    /// ditto
    void eulerRotation(in Vector3f value) pure
    {
        mRotation = quat.eulerRotation(value.x, value.y, value.z);
        recalculateLocalMatrix();
    }

    /// The scaling of this transform.
    Vector3f scale() nothrow  pure const
    {
        return mScale;
    }

    /// ditto
    void scale(in Vector3f value) pure
    {
        mScale = value;
        recalculateLocalMatrix();
    }
}
