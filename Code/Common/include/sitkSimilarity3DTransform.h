/*=========================================================================
*
*  Copyright NumFOCUS
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*         http://www.apache.org/licenses/LICENSE-2.0.txt
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
*
*=========================================================================*/
#ifndef sitkSimilarity3DTransform_h
#define sitkSimilarity3DTransform_h

#include "sitkCommon.h"
#include "sitkTransform.h"

namespace itk
{
namespace simple
{

/** \class Similarity3DTransform
 * \brief A similarity 3D transform with rotation as a versor, and
 * isotropic scaling around a fixed center with translation.
 *
 * \sa itk::Similarity3DTransform
 */
class SITKCommon_EXPORT Similarity3DTransform
  : public Transform
{
public:
typedef Similarity3DTransform Self;
typedef Transform             Superclass;

~Similarity3DTransform() override;

// construct identity
Similarity3DTransform();

Similarity3DTransform( const Similarity3DTransform & );

explicit Similarity3DTransform( const Transform & );

Similarity3DTransform( double scaleFactor, const std::vector< double > &versor,
                       const std::vector< double > &translation=std::vector< double >(3, 0.0),
                       const std::vector< double > &fixedCenter=std::vector< double >(3, 0.0) );

Similarity3DTransform( double scaleFactor, const std::vector< double > &axis, double angle,
                       const std::vector< double > &translation=std::vector< double >(3, 0.0),
                       const std::vector< double > &fixedCenter=std::vector< double >(3, 0.0) );

Similarity3DTransform &operator=( const Similarity3DTransform & );

/** Name of this class */
std::string GetName() const override { return std::string ("Similarity3DTransform"); }

/** fixed parameter */
SITK_RETURN_SELF_TYPE_HEADER SetCenter(const std::vector<double> &params);
std::vector<double> GetCenter( ) const;


/** parameter */
SITK_RETURN_SELF_TYPE_HEADER SetRotation(const std::vector<double> &versor);
SITK_RETURN_SELF_TYPE_HEADER SetRotation(const std::vector<double> &axis,  double angle);
std::vector<double> GetVersor() const;

SITK_RETURN_SELF_TYPE_HEADER SetScale(double scale);
double GetScale() const;

std::vector<double> GetTranslation( ) const;
SITK_RETURN_SELF_TYPE_HEADER SetTranslation(const std::vector<double>& translation);


/** additional methods */
SITK_RETURN_SELF_TYPE_HEADER Translate(const std::vector<double> &offset);
std::vector<double> GetMatrix() const;
SITK_RETURN_SELF_TYPE_HEADER SetMatrix(const std::vector<double> &matrix, double tolerance = 1e-10);

protected:

void SetPimpleTransform( PimpleTransformBase *pimpleTransform ) override;

private:

using Superclass::AddTransform;

void InternalInitialization(itk::TransformBase *transform);

template <typename TransformType>
void InternalInitialization(TransformType *transform);

std::function<void(const std::vector<double>&)> m_pfSetCenter;
std::function<std::vector<double>()> m_pfGetCenter;
std::function<void(const std::vector<double>&)> m_pfSetRotation1;
std::function<void(const std::vector<double>,double&)> m_pfSetRotation2;
std::function<std::vector<double>()> m_pfGetVersor;
std::function<void(double)> m_pfSetScale;
std::function<double()> m_pfGetScale;
std::function<void(const std::vector<double>&)> m_pfSetTranslation;
std::function<std::vector<double>()> m_pfGetTranslation;
std::function<void(const std::vector<double> &)> m_pfTranslate;
std::function<std::vector<double>()> m_pfGetMatrix;
std::function<void(const std::vector<double>&, double)> m_pfSetMatrix;
};

}
}

#endif // sitkSimilarity3DTransform_h
