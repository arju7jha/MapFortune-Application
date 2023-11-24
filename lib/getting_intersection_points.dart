import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:math';

double calculateDistance(Offset point1, Offset point2) {
  double deltaX = point2.dx - point1.dx;
  double deltaY = point2.dy - point1.dy;
  double distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2));
  return distance;
}

Offset find_first_intersection (List<Offset> polyVertices, Offset center, Offset Touch)
{
  List<List<Offset>> may_be_point =[];
  for (int i = 0; i < polyVertices.length -1 ; i++)
  {
    Offset point1 = polyVertices[i];
    Offset point2 = polyVertices[i+1];
    final slope = (Touch.dx - center.dx) != 0 ? (Touch.dy - center.dy) / (Touch.dx - center.dx) : double.infinity;
    final intercept = center.dy - slope * center.dx;

    double comparator1 = (point1.dy-slope*point1.dx - intercept);
    double comparator2 = (point2.dy-slope*point2.dx - intercept);

    if(comparator1*comparator2 < 0)
    {
      List<Offset> temp = [point1, point2];
      may_be_point.add(temp);
    }
  }

  double temp = double.infinity;
  Offset ans = Offset(double.infinity,double.infinity) ;
  for(int i=0; i<may_be_point.length ; i++)
  {
    Offset  intersection = calculate_intersection(Touch, center, may_be_point[i][0], may_be_point[i][1]);
    double value = calculateDistance(intersection, Touch);
    if(value<temp)
    {
      ans= intersection;
      temp=value;
    }
  }
  return ans;
}

int find_first_edge (List<Offset> polyVertices, Offset center, Offset Touch)
{
  List<List<Offset>> may_be_point =[];
  for (int i = 0; i < polyVertices.length -1 ; i++)
  {
    Offset point1 = polyVertices[i];
    Offset point2 = polyVertices[i+1];
    final slope = (Touch.dx - center.dx) != 0 ? (Touch.dy - center.dy) / (Touch.dx - center.dx) : double.infinity;
    final intercept = center.dy - slope * center.dx;

    double comparator1 = (point1.dy-slope*point1.dx - intercept);
    double comparator2 = (point2.dy-slope*point2.dx - intercept);

    if(comparator1*comparator2 < 0)
    {
      List<Offset> temp = [point1, point2];
      may_be_point.add(temp);
    }
  }

  double temp = double.infinity;
  List<Offset> ans= [];
  for(int i=0; i<may_be_point.length ; i++)
  {
    Offset  intersection = calculate_intersection(Touch, center, may_be_point[i][0], may_be_point[i][1]);
    double value = calculateDistance(intersection, Touch);
    if(value<temp)
    {
      List<Offset>  temp_edge = [may_be_point[i][0],may_be_point[i][1]];
      ans=temp_edge;
      temp=value;
    }
  }
  int index = -1;
  for (int i = 0; i < polyVertices.length -1 ; i++)
  {
    if(polyVertices[i]==ans[0] && polyVertices[i+1]==ans[1])
      index=i;
  }

  return index+1;

}


double calculate_angle (Offset point1, Offset point2, Offset point3)
{
  final vector12 = point2 - point1;
  final vector32 = point2 - point3;

  final magnitude12 = vector12.distance;
  final magnitude32 = vector32.distance;

  final dotProduct = vector12.dx * vector32.dx + vector12.dy * vector32.dy;
  final division = dotProduct / (magnitude12 * magnitude32);
  final angleRadians = acos(division);
  final angleDegrees = angleRadians * 180 / pi;

  return angleDegrees;
}

Offset calculate_intersection(Offset touch, Offset center, Offset point1, Offset point2) {
  final slope1 = (point2.dy - point1.dy) / (point2.dx - point1.dx);
  final slope2 = (touch.dy - center.dy) / (touch.dx - center.dx);
  final intercept1 = point1.dy - slope1 * point1.dx;
  final intercept2 = center.dy - slope2 * center.dx;

  double intersectionX;
  double intersectionY;

  intersectionX = (intercept2 - intercept1) / (slope1 - slope2);
  intersectionY = slope1 * intersectionX + intercept1;

  return Offset(intersectionX, intersectionY);
}

double calculate_area_of_triangle(Offset point1, Offset point2, Offset point3) {
  double x1 = point1.dx;
  double y1 = point1.dy;
  double x2 = point2.dx;
  double y2 = point2.dy;
  double x3 = point3.dx;
  double y3 = point3.dy;

  double area = 0.5 * ((x1 * (y2 - y3)) + (x2 * (y3 - y1)) + (x3 * (y1 - y2))).abs();
  return area;
}

// double rotateSlope(double originalSlope) {
//   // Convert the angle to radians
//   double theta = 22.5 * (pi / 180);
//
//   // Calculate the new slope using the rotation matrix
//   double cosTheta = cos(theta);
//   double sinTheta = sin(theta);
//   double newSlope = originalSlope * cosTheta + 1 * (-sinTheta) / sinTheta + 1 * cosTheta;
//
//   return newSlope;
// }
double calculateNewSlope(Offset pointA, Offset pointB) {
  double originalSlope = (pointB.dy - pointA.dy) / (pointB.dx - pointA.dx);
  double rotationAngle = 22.5; // Rotation angle in degrees

  // Convert the rotation angle to radians
  double rotationAngleRad = rotationAngle * pi / 180.0;

  // Calculate the new slope using the rotation formula
  double tanTheta = tan(rotationAngleRad);
  double newSlope = (tanTheta + originalSlope) / (1 - originalSlope * tanTheta);

  return newSlope;
}

Offset find_intersected_point(Offset  point1, Offset point2, int index, List<Offset> polyVertices)
{
  Offset point3 = polyVertices[index];
  Offset point4 = polyVertices[index-1];

  // double originalslope = (point2.dy - point1.dy) / (point2.dx - point1.dx);
  final slope1 = calculateNewSlope(point1,point2);
  final slope2 = (point3.dy - point4.dy) / (point3.dx - point4.dx);
  final intercept1 = point2.dy - slope1 * point2.dx;
  final intercept2 = point3.dy - slope2 * point3.dx;

  double intersectionX;
  double intersectionY;

  intersectionX = (intercept2 - intercept1) / (slope1 - slope2);
  intersectionY = slope1 * intersectionX + intercept1;

  return Offset(intersectionX, intersectionY);
}




List<double> find_areas_of_sectors(List<Offset> polyVertices, Offset center, Offset Touch)
{
  List<Offset> intersection_points =[];
  List<double> areas =[];
  Offset point1 = find_first_intersection(polyVertices, center, Touch);
  intersection_points.add(point1);
  int  first_vertex_index = find_first_edge(polyVertices,center,Touch);
  Offset point2 = center;
  Offset point3 = polyVertices[first_vertex_index];

  int lines = 1;
  int index= first_vertex_index;
  double temp_area=0;
  while(lines<=16)
  {
    point3=polyVertices[index];
    Offset main_point = point1;
    if(calculate_angle(point1,point2,point3) >= 22.5)
    {
      Offset intersected_point = find_intersected_point(point1,point2,index,polyVertices);
      double area = temp_area + calculate_area_of_triangle(main_point, point2, intersected_point);
      areas.add(area);
      point1=intersected_point;
      lines++;
      intersection_points.add(intersected_point);
      temp_area=0;
    }
    else
    {
      temp_area= temp_area + calculate_area_of_triangle(point1, point2, point3);
      main_point= polyVertices[index];
      index++;

      if(index==polyVertices.length)
        index=1;
    }
  }
  return areas;
}

List<Offset> findallintersectionpoints(List<Offset> polyVertices, Offset center, Offset Touch)
{
  List<Offset> intersection_points =[];
  Offset point1 = find_first_intersection(polyVertices, center, Touch);
  intersection_points.add(point1);
  int  first_vertex_index = find_first_edge(polyVertices,center,Touch);
  Offset point2 = center;
  Offset point3 = polyVertices[first_vertex_index];

  int lines = 1;
  int index= first_vertex_index;
  while(lines<16)
  {
    point3=polyVertices[index];
    if(calculate_angle(point1,point2,point3) >= 22.5)
    {
      Offset intersected_point = find_intersected_point(point1,point2,index,polyVertices);
      point1=intersected_point;
      lines++;
      intersection_points.add(intersected_point);
    }
    else
    {
      index++;

      if(index==polyVertices.length)
        index=1;
    }
  }
  return  intersection_points;
}











