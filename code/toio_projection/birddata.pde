// Class created with reference from DeepSeek

import java.util.ArrayList;
import java.util.List;

public class BirdData {
    public List<Point> points; // List to store (x, y) coordinate points
    public String imagePath;
    public String lapEndDateLabel; // label for the end of the timeline
    
    public BirdData() {
        points = new ArrayList<>();
        imagePath = "";
    }
    // Method to add a point with a label
    public void addPoint(int x, int y, String label) {
        points.add(new Point(x, y, label));
    }
    // Method to add a point without a label
    public void addPoint(int x, int y) {
        points.add(new Point(x, y)); // Calls the constructor without a label
    }
    
    public int getNumPoints() {
        return points.size();
    }
    public void printPoints() {
        for (Point point : points) {
            //System.out.println("(" + point.x + ", " + point.y + ") - " + point.label);
        }
    }
}
