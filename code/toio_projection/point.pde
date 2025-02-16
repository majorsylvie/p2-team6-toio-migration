// class generated by DeepSeek

class Point {
    int x, y;       // Coordinates of the point
    String label;    // Label for the point (defaults to an empty string)

    // Constructor with label
    public Point(int x, int y, String label) {
        this.x = x;
        this.y = y;
        this.label = label;
    }

    // Constructor without label (defaults to an empty string)
    public Point(int x, int y) {
        this(x, y, ""); // Calls the other constructor with an empty string
    }
}
