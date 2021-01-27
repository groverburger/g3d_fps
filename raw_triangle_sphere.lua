float3 p0, p1, p2; // triangle corners
float3 center; // sphere center
float3 N = normalize(cross(p1 – p0, p2 – p0)); // plane normal
float dist = dot(center – p0, N); // signed distance between sphere and plane
if(!mesh.is_double_sided() && dist > 0)
  continue; // can pass through back side of triangle (optional)
if(dist < -radius || dist > radius)
  continue; // no intersection

float3 point0 = center – N * dist; // projected sphere center on triangle plane

// Now determine whether point0 is inside all triangle edges: 
float3 c0 = cross(point0 – p0, p1 – p0) 
float3 c1 = cross(point0 – p1, p2 – p1) 
float3 c2 = cross(point0 – p2, p0 – p2)
bool inside = dot(c0, N) <= 0 && dot(c1, N) <= 0 && dot(c2, N) <= 0;

float3 ClosestPointOnLineSegment(float3 A, float3 B, float3 Point)
{
  float3 AB = B – A;
  float t = dot(Point – A, AB) / dot(AB, AB);
  return A + saturate(t) * AB; // saturate(t) can be written as: min((max(t, 0), 1)
}

float radiussq = radius * radius; // sphere radius squared

// Edge 1:
float3 point1 = ClosestPointOnLineSegment(p0, p1, center);
float3 v1 = center – point1;
float distsq1 = dot(v1, v1);
bool intersects = distsq1 < radiussq;

// Edge 2:
float3 point2 = ClosestPointOnLineSegment(p1, p2, center);
float3 v2 = center – point2;
float distsq2 = dot(vec2, vec2);
intersects |= distsq2 < radiussq;

// Edge 3:
float3 point3 = ClosestPointOnLineSegment(p2, p0, center);
float3 v3 = center – point3;
float distsq3 = dot(v3, v3);
intersects |= distsq3 < radiussq;

if(inside || intersects)
{
  float3 best_point = point0;
  float3 intersection_vec;

  if(inside)
  {
    intersection_vec = center – point0;
  }
  else  
  {
    float3 d = center – point1;
    float best_distsq = dot(d, d);
    best_point = point1;
    intersection_vec = d;

    d = center – point2;
    float distsq = dot(d, d);
    if(distsq < best_distsq)
    {
      distsq = best_distsq;
      best_point = point2;
      intersection_vec = d;
    }

    d = center – point3;
    float distsq = dot(d, d);
    if(distsq < best_distsq)
    {
      distsq = best_distsq;
      best_point = point3; 
      intersection_vec = d;
    }
  }

  float3 len = length(intersection_vec);  // vector3 length calculation: 
  sqrt(dot(v, v))
  float3 penetration_normal = penetration_vec / len;  // normalize
  float penetration_depth = radius – len; // radius = sphere radius
  return true; // intersection success
}
